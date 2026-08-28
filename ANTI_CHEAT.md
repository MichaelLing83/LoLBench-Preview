# Anti-cheat policy

The gold answer for every LoLBench task is a **public merged pull request** that
exists in most models' training data and is mirrored across many hosts. So on
LoLBench, "implementing the feature" and "retrieving the merged PR" would produce
the same graded artifact. The benchmark is therefore hardened so that a graded
`reward = 1.0` reflects a genuine implementation, not retrieval.

Prevention has four layers. The first three are enforced by the task images and
the Harbor run; they need no configuration.

## 1. Network egress allowlist (agent run)

While the agent is **solving the task**, its container runs under a **strict
allowlist**, enforced by Harbor's `harbor-docker-egress-control-sidecar`. Each
task's `task.toml` declares:

```toml
[agent]
network_mode  = "allowlist"
allowed_hosts = ["openrouter.ai", "api.openai.com", "api.anthropic.com"]
```

Only the model endpoints are reachable. **`github.com`, `pypi.org`, package/OS
mirrors, and Maven Central are all blocked** — the agent cannot fetch the PR, the
post-feature source, or a released artifact.

Because Maven Central is unreachable, the Java tasks build from a **warm dependency
cache baked into the image** (Maven `.m2` for Flink, Gradle cache for Kafka). This
also closes the `-sources.jar` / `-test-sources.jar` leak (a released source jar can
contain the gold + held-out tests) without any proxy — there is simply no path to
Maven at agent time.

> Running a different model? Add **only** the model host with
> `--allow-agent-host <host>`. Never allowlist a source host. The wrapper scripts
> add the endpoint automatically for common providers and **refuse** a source host
> passed via `LOLBENCH_ALLOW_HOSTS`.

Adding a model endpoint does not widen the boundary — it swaps one model host for
another. Verified from inside a live agent container running as the `agent` user
with `--allow-agent-host api.deepseek.com`: `api.deepseek.com` reachable (HTTP 401,
i.e. the API answered), while `github.com`, `api.github.com`,
`raw.githubusercontent.com`, `codeload.github.com`, `pypi.org`,
`files.pythonhosted.org`, `repo.maven.apache.org`, `gitee.com`, and
`apache.googlesource.com` all failed to connect (TLS intercepted).

The agent's own tooling (e.g. OpenCode's Node runtime) is installed in a
preceding **setup** step whose commands are fixed by the harness, not chosen by
the model; the allowlist tightens for the task-solving run that follows.

## 2. Image hardening (build time)

Each eval image is built so the answer is not sitting on disk. Per-task policy is
recorded in `harbor_tasks/<id>/environment/source_audit.json`:

- The CPython images fetch **only** the declared base-commit ancestry and
  additionally **assert `git fsck --unreachable` finds nothing**. The Ruff and Java
  images fetch from the merge commit (GitHub blocks shallow fetch of arbitrary
  non-tip SHAs), check out the base commit, then remove `refs`/`remotes`/`reflogs`,
  repack, and `git prune --expire=now` to drop the unreachable post-feature objects.
- Auxiliary reference source trees are removed (e.g. the copyable whole-module
  stdlib deliverables `zoneinfo` = PEP 615, `tomllib` = PEP 680).
- Remaining auxiliary toolchains are made root-owned and non-enumerable to the
  (non-root) agent user.

## 3. Isolated grading

The **hidden bundle** — the F2P/P2P test patches and the test selectors — lives
under `harbor_tasks/<id>/tests/private/` and is mounted **only into the separate
verifier container**, never into the agent container. (The reference solution lives
separately under `harbor_tasks/<id>/solution/` and is applied only by the `oracle`
agent.) The agent submits with `lolbench-submit`, which captures its working-tree
diff against a baseline; the verifier then restores any paths the hidden test
patches own to their base state, applies that diff plus the hidden tests in a fresh
container, and grades. The agent never sees the tests it is graded on.

## 4. Detection (defense-in-depth)

Prevention is a hard boundary, but two residual channels are worth auditing when
you care about the integrity of a headline number:

- **Model memorization.** No sandbox can stop a model from reproducing public
  training-data code from its weights. A `reward = 1.0` on a pre-cutoff PR with
  all egress blocked may be memorized rather than reasoned. Treat cross-task
  patterns (e.g. byte-exact reproduction of the merged commit) as a signal to
  audit, not an automatic pass.
- **Patch↔gold similarity.** A captured patch that is a near-verbatim copy of the
  gold over deliverable (non-test) files is a retrieval signal. Comparing the
  submitted patch to `harbor_tasks/<id>/solution/solution.patch` (e.g. Jaccard over
  added lines **and** file paths) flags copies; deterministically-generated files
  (parsers, AST tables) legitimately match and should be excluded.

## What this repo does and doesn't guarantee

The task images + Harbor allowlist make **retrieval via network or on-disk
source** infeasible for the agent. They do **not** by themselves rule out
**memorization**; that requires the per-run auditing above. When publishing a
number, state the model, the suite (`orig`/`aug`/`union`), and whether a
memorization audit was applied.
