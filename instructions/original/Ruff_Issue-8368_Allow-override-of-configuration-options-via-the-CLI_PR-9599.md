> Implement the requirement described below in the project's source tree.
> Put implementation changes in `solution.patch`. If you add tests, put
> them in `test.patch`; tests are optional and must not be included in
> `solution.patch`.
>
> This environment has no outbound internet access — `curl`/`wget`, `git fetch`/`clone`, package installs, and web fetch/search will all fail. Implement the requirements using only the code already in the workspace and your own knowledge; do not attempt to fetch or search external resources.

---

# Allow override of configuration options via the CLI

Currently, Ruff includes many configuration options that are only available via a configuration file. These options should be available via the CLI as well so users can either:

- Provide configuration options without defining a configuration file
- Override configuration options per invocation of Ruff without modifying files

There have been previous requests for this, but I could not find them. If you know where they're at please share so we can have more historical context here.

## Proposals

We will expose this capability by overloading the existing `--config` flag, following Cargo's precedent of using `--config` both to point at a configuration file and to override individual options. Ruff already uses `--config <CONFIG>` to name a configuration file, so each `--config` value is now interpreted as either a path to a `.toml` file or a single inline `<KEY> = <VALUE>` TOML pair overriding one option: a value that parses as TOML is treated as an override, and otherwise it is treated as a file path.

The flag is repeatable, but each occurrence carries exactly one file or one override, so packing two overrides into a single `--config` is rejected. A value that looks like an override but is not valid TOML, or a file path that does not exist, is rejected with a tip explaining that a `--config` flag must either be a path to a `.toml` configuration file or a TOML `<KEY> = <VALUE>` pair overriding a specific configuration option. At most one configuration file may be supplied on the command line, and `--config` cannot be combined with `--isolated`.
