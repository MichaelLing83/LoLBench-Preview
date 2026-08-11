# LoLBench Instance: CPython PR-19909 (PEP 615: zoneinfo)

> **Requirement**: [PEP 615](https://peps.python.org/pep-0615/) — "Support for the IANA Time Zone Database in the Standard Library"
> **Implementing PR**: [python/cpython#19909](https://github.com/python/cpython/pull/19909)
> **base_commit**: `6e8cda91d92da72800d891b2fc2073ecbc134d98`  (2020-05-12, parent of squash-merge commit `62972d9d`)
> **Language mix**: 4 new Python modules under `Lib/zoneinfo/` (1060 lines) + 1 new C extension `Modules/_zoneinfo.c` (2695 lines) + build wiring (configure / configure.ac / Makefile.pre.in / setup.py / Modules/Setup / Lib/sysconfig.py).

This directory ships everything an evaluator needs to score an agent's
`solution.patch` against this instance, plus the recipes used to build
the eval + coverage images.

> **Status — validated 2026-05-21.** The eval image, augmented suites,
> mutant arm, and hybrid coverage image were rebuilt and checked locally.
> Union coverage is 88.0%, above the 80% gate.

> **Base-commit note.** GitHub reports the PR base as
> `6e57237faf…` (PR-creation-time tip of main). PR-19909 was squash-
> merged into main on 2020-05-16; the merge commit `62972d9d…` has a
> single parent `6e8cda91…`, and diffing against that parent isolates
> the PR contribution from ~3 months of unrelated drift on main. Same
> pattern as PEP-617 / PEP-634 / PEP-654 / PEP-669 / PEP-680.

---

## Evaluating `solution.patch` under test modes

This bundle ships an augmented sidecar, so the runner understands three suites:

| Suite | What it runs | F2P | P2P |
| --- | --- | ---: | ---: |
| `orig` | original PR-derived hidden selectors | 44 | 89 |
| `aug` | mutation/coverage-driven sidecar selectors only | 7 | 4 |
| `union` | `orig` plus `aug`; canonical for refreshed scoring | 51 | 93 |

The wrapper default is `orig` unless the script or environment overrides it. Use `union` for leaderboard or refreshed audit runs when it is available; use `orig` and `aug` for diagnosis.

The current `eval.sh` wrapper does not expose a `--suite` flag. Run the image directly when you need a non-default suite:

```bash
docker run --rm \
  --network=none \
  --memory 7g --cpus 4 \
  -e LOLBENCH_SUITE=union \
  -v $(pwd)/solution.patch:/in/solution.patch:ro \
  -v $(pwd)/out:/out \
  lolbench/cpython-pr-19909:1
```

## 1. Bundle layout

```
dockers/CPython_PEP-615_..._PR-19909/
├── README.md
├── eval.sh                  ← evaluator-facing wrapper
├── validate.sh              ← grader-only §7 invariant check
├── Dockerfile               ← lolbench/cpython-pr-19909:1
├── spec.json
├── solution.patch           ← 11 files (4 new Lib/zoneinfo/*.py + Modules/_zoneinfo.c + 6 build glue)
├── eval_tests.patch         ← 6 files (Lib/test/test_zoneinfo/* incl. zoneinfo_data.json)
├── eval_tests_aug.patch     ← sidecar augmented tests (new files only)
├── omitted.patch            ← 10 files (Windows/MSI build + .travis.yml + GH coverage CI + Misc reqs)
├── f2p.txt                  ← 44 public-API / module-level methods (14 Py-impl + 28 C-impl + 2 ExtensionBuiltTest sentinels)
├── f2p_aug.txt              ← 7 augmented F2P selectors
├── p2p.txt                  ← 89 stable public-API methods (P2P/F2P = 2.02×)
├── p2p_aug.txt              ← 4 augmented P2P selectors
├── run_tests.sh
├── test_augmentation/       ← augmented test sources + audit
├── coverage_out/            ← final orig / aug / union coverage reports
├── base/                    ← reused lolbench/cpython-base:1
└── coverage/                ← hybrid coverage.py + gcov bundle
```

zoneinfo's C extension is a leaf shared library; no special caps,
`--network=none`, default seccomp.

---

## 2. Building the images

```bash
docker build -t lolbench/cpython-base:1 -f base/Dockerfile base/
docker build -t lolbench/cpython-pr-19909:1 .
docker build -t lolbench/cpython-pr-19909-coverage:1 -f coverage/Dockerfile .
```

The patches were derived from `git diff 6e8cda91…62972d9d`, split
by file role. Patch math: 11 (solution) + 6 (eval_tests) + 10
(omitted) = 27 PR files, matching `data/pr_files_cache/...PR-19909.json`.

---

## 3. F2P / P2P selection

### 3.1 Pre-state failure mode

At pre-state, the test loader resolves
`test.test_zoneinfo.test_zoneinfo.<class>.<method>`. Importing the
test package executes `test_zoneinfo.py`'s module body, which has the
top-level line:

```python
py_zoneinfo, c_zoneinfo = test_support.get_modules()
```

`get_modules()` does `import zoneinfo as c_module`. At base_commit
neither `Lib/zoneinfo/` (pure-Python impl) nor `Modules/_zoneinfo.c`
(C accelerator) exists → `ModuleNotFoundError` → all 44 F2P
selectors ERROR identically at module-load time.

### 3.2 F2P (44 methods)

14 Py-impl + 28 C-impl + 2 ExtensionBuiltTest sentinels:

| Class | Impl | # | What it exercises |
| --- | --- | ---: | --- |
| `ZoneInfoTest` | Py | 6 | `ZoneInfo(key)` / `str` / `repr` / `.key` / bad-key / unambiguous / UTC |
| `WeirdZoneTest` | Py | 2 | Edge-case zones (one transition, one-DST) |
| `TZStrTest` | Py | 2 | POSIX TZ strings (localized + invalid) |
| `ZoneInfoCacheTest` | Py | 1 | Strong-ref cache semantics |
| `ZoneInfoPickleTest` | Py | 1 | `ZoneInfo.from_file` pickle roundtrip |
| `TzPathTest` | Py | 2 | `PYTHONTZPATH` env var + `reset_tzpath` kwarg |
| `CZoneInfoTest` | C | 12 | All base tests + bad-keys-paths + bad-zones + fromutc-errors + folds/gaps + folds-from-utc + time-variable-offset + time-fixed-offset + unique `test_fold_mutate` |
| `CWeirdZoneTest` | C | 5 | one-transition + one-zone-dst + no-tz-str + empty-zone + fixed-offset-phantom |
| `CTZStrTest` | C | 3 | localized + from-utc + invalid |
| `CZoneInfoCacheTest` | C | 3 | strong-refs + no-cache + clear-cache-explicit-none |
| `CZoneInfoPickleTest` | C | 2 | cache-hit + from-file |
| `CCallingConventionTest` | C | 1 | `ZoneInfo.from_file` calling convention |
| `ExtensionBuiltTest` | sentinel | 2 | `test_cache_location` + `test_gc_tracked` — prove the C extension was actually loaded (see §3.5) |

The 42 ZoneInfo/Weird/TZStr/Cache/Pickle/TzPath/CallingConvention
selectors exercise only the documented public surface:
`zoneinfo.ZoneInfo`, `.key`, `.from_file`, `.clear_cache`,
`zoneinfo.TZPATH`, `zoneinfo.reset_tzpath`, plus the pickle
protocol.

The 2 `ExtensionBuiltTest` selectors are **C-accelerator presence
sentinels** added per Codex round 1 M1. They introspect
implementation-internal differences (`Py-impl.ZoneInfo._weak_cache`
attribute exists; `C-impl.ZoneInfo._weak_cache` does not; same for
`gc.is_tracked`). Without these sentinels, an agent could ship only
the pure-Python files and the `CZoneInfoTest.*` selectors would
silently pass against the Py-impl fallback (because
`Lib/zoneinfo/__init__.py` catches `ImportError` and falls back).

**Policy decision (Codex round 2 H1 clarification):** the benchmark
INTENTIONALLY scores "C accelerator must be present" because
`Modules/_zoneinfo.c` is ~2695 lines — the bulk of the patch. The
sentinels are accepted as a deliberate exception to the
public-surface rule, not as a normal F2P. Their private-symbol
references (`_weak_cache`, `gc.is_tracked`) are recorded in
`spec.json.public_surface_allowlist[1].policy_decision`.

### 3.3 P2P (89 methods)

From four pre-existing test files that the PR does **not** touch:

| File / Class | # |
| --- | ---: |
| `test_grammar.TokenTests` | 7 |
| `test_grammar.GrammarTests` | 25 |
| `test_ast.AST_Tests` | 14 |
| `test_ast.ASTHelpers_Test` | 11 |
| `test_ast.ConstantTests` | 5 |
| `test_ast.EndPositionTests` | 5 |
| `test_sys.SysModuleTest` | 2 |
| `test_module.ModuleTests` | 12 |

Ratio P2P/F2P = 2.02×.

The 2 `test_sys` (`test_sys_flags`, `test_getframe`) + 12 `test_module`
selections give P2P some locality with PEP-615's "new stdlib module +
new C extension" theme while remaining byte-identical pre/post.
`test_getframe` uses `sys._getframe` which is allowlisted (see
§3.5).

### 3.4 Augmented sidecar suites

The sidecar suite adds 7 F2P selectors in
`Lib/test/test_zoneinfo/test_zoneinfo_aug.py` and 4 P2P selectors in
`Lib/test/test_zoneinfo_stability_aug.py`.

F2P targets all 18 committed PEP-615 mutants through public `zoneinfo`
and `datetime` behavior: constructor identity and cache invalidation,
`no_cache` / `from_file` pickle contracts, TZPATH ordering and
environment reset, `tzdata.zoneinfo` fallback, future POSIX footer
rules, fold-sensitive offsets, string representation, and
`ZoneInfoNotFoundError` as a `KeyError`.

P2P avoids importing `zoneinfo` and pins pre-existing fixed-offset
`datetime`, pickle, and `sysconfig` behavior under the PEP's Backwards
Compatibility section.

### 3.5 Out-of-scope + allowlist

Out-of-scope (no F2P/P2P reaches these):

- `zoneinfo._zoneinfo._*` / `zoneinfo._common._*` /
  `zoneinfo._tzpath._*` — package-private helpers.
- top-level `_zoneinfo.*` — the C extension module imported by
  `Lib/zoneinfo/__init__.py` via `from _zoneinfo import ZoneInfo`.

Allowlisted private symbols (`spec.json.public_surface_allowlist`):

- **`sys._getframe`** — referenced by P2P
  `test_sys.SysModuleTest.test_getframe`. Documented CPython
  implementation detail, used pervasively in tracing/profiling
  frameworks. Pre-existing, untouched by this PR.
- **`py_zoneinfo.ZoneInfo._weak_cache` (presence) /
  `gc.is_tracked(c_zoneinfo.ZoneInfo)` (sentinel introspection)** —
  used only by the 2 `ExtensionBuiltTest` F2P sentinels to verify
  the C extension was actually loaded. The agent is NOT required to
  implement these — they're sentinel introspections of the existing
  test fixture and pre-existing CPython infrastructure.

---

## 4. Validation status

`spec.json.validated_at` is `2026-05-21`. `./validate.sh` passed for
the original, augmented, and union suites:

- **orig**: pre 44 F2P ERROR / 89 P2P PASS; post 44 F2P PASS /
  89 P2P PASS.
- **aug**: pre 7 F2P ERROR / 4 P2P PASS; post 7 F2P PASS /
  4 P2P PASS.
- **union**: pre 51 F2P ERROR / 93 P2P PASS; post 51 F2P PASS /
  93 P2P PASS.
- **mutants**: 18/18 committed PEP-615 mutants killed by F2P with
  P2P clean under the union suite.

Hybrid coverage reports are in `coverage_out/`. The final union report
covers 1449 of 1647 executable patch lines (88.0%). The C coverage
parser excludes gcovr rows marked `gcovr/noncode`, so comments and
braces are not counted as executable lines.

---

## 5. Troubleshooting

See `docs/executable_environment_plan.md` §17. PEP-615 specifics:

- **Hybrid coverage**: `Lib/zoneinfo/*.py` uses `coverage.py 7.4.4`
  (pip-installed against the freshly-built `./python`);
  `Modules/_zoneinfo.c` uses gcov via `gcovr --filter
  Modules/_zoneinfo\.c`. The coverage image rebuilds CPython with
  `CFLAGS="--coverage -O0 -g" LDFLAGS="--coverage"` so the new C
  extension emits `.gcno` + `.gcda` files. `run_coverage.sh`
  snapshots `.gcda` between the F2P and P2P lanes.
- **configure re-run on patch apply**: `solution.patch` modifies
  `configure.ac` (and the generated `configure`). The eval runner's
  `needs_reconfig` branch detects this and re-runs `./configure`
  before `make` so setup.py picks up the new `Modules/_zoneinfo.c`
  entry.
- **base_commit vs GitHub PR-base**: same pattern as prior CPython
  instances — use the merge parent `6e8cda91…`.

## Platform and resources

- Platform support: `not restricted in spec.json`
- Resource caps: CPU `4`, memory `7g`
- Timeout: `not recorded` seconds
- Eval-time network: disabled with `--network=none`.


<!-- LoLBench audit completeness sections -->

## Bundle file map

| Path | Purpose |
| --- | --- |
| `README.md` | bundle documentation |
| `eval.sh` | evaluator-facing wrapper |
| `validate.sh` | pre/post validation wrapper |
| `Dockerfile` | correctness eval image recipe |
| `spec.json` | instance metadata and selector contract |
| `solution.patch` | reference implementation patch for validation |
| `eval_tests.patch` | hidden original eval tests |
| `eval_tests_aug.patch` | hidden augmented eval tests |
| `omitted.patch` | excluded PR hunks |
| `f2p.txt` | original fail-to-pass selectors |
| `p2p.txt` | original pass-to-pass selectors |
| `f2p_aug.txt` | augmented fail-to-pass selectors |
| `p2p_aug.txt` | augmented pass-to-pass selectors |
| `run_tests.sh` | container test runner |
| `coverage/` | coverage image recipe and scripts |
| `coverage_out/` | coverage reports |
| `test_augmentation/` | augmentation audit/source notes |

<!-- coverage-summary -->
## Coverage (orig / aug / union)

**86.34% / 87.98% / 87.98%** — each suite's covered lines over the **union** instrumented denominator (so `union ≥ max(orig, aug)`); see `coverage_out/coverage_report_{orig,aug,union}.json` and `docs/coverage_calculation.md`.
