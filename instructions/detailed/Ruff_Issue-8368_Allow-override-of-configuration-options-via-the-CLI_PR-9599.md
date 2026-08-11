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


### Implementation Guidance

1. In `crates/ruff/src/args.rs`, update `ConfigArguments.config_file`, `ConfigArguments.from_cli_arguments`, `ConfigurationTransformer.transform`, `CheckCommand.partition`, `FormatCommand.partition`, `TomlParseFailureKind.fmt`, `TomlParseFailure.fmt`, `ValueParserFactory.value_parser`, and `TypedValueParser.parse_ref`. Core implementation of the dual-purpose `--config` flag. Adds `SingleConfigArgument` enum distinguishing file paths from inline TOML overrides. Adds `ConfigArgumentParser` that parses each `--config` value: if it contains `=` and parses as valid TOML, it is treated as an override; otherwise it is treated as a config file path. Adds `ConfigArguments` struct (replacing `CliOverrides`) that holds both the optional config file path and a vector of `Configuration` overrides. Adds `TomlParseFailure` / `TomlParseFailureKind` for error reporting. Validates that at most one config file is specified and that overrides use the correct TOML prefix (`[tool.ruff]` keys use bare names, `pyproject.toml` keys require `tool.ruff.` prefix).

2. In `crates/ruff/src/commands/add_noqa.rs`, update `add_noqa`. Implements changes for this section.

3. In `crates/ruff/src/commands/check.rs`, update `check` and `unreadable_files`. Implements changes for this section.

4. In `crates/ruff/src/commands/check_stdin.rs`, update `check_stdin`. Implements changes for this section.

5. In `crates/ruff/src/commands/format.rs`, update `format`. Implements changes for this section.

6. In `crates/ruff/src/commands/format_stdin.rs`, update `format_stdin`. Implements changes for this section.

7. In `crates/ruff/src/commands/show_files.rs`, update `show_files`. Implements changes for this section.

8. In `crates/ruff/src/commands/show_settings.rs`, update `show_settings`. Implements changes for this section.

9. In `crates/ruff/src/lib.rs`, update `format` and `check`. Updates the top-level `check` and `format` entry points to accept `ConfigArguments` instead of separate `config: Option<PathBuf>` and `overrides: CliOverrides` parameters. Constructs the `ConfigArguments` from clap-parsed arguments.

10. In `crates/ruff/src/resolve.rs`, update `resolve`. Updates `resolve` to accept `ConfigArguments` and apply the override `Configuration` objects on top of the file-based configuration, in order. Each override is merged via `Configuration::combine`.

11. In `crates/ruff_dev/src/format_dev.rs`, update `parse_cli`, `find_pyproject_config`, and `ruff_check_paths`. Updates the dev format tool's `parse_cli` to use `ConfigArguments::default` instead of the old `CliOverrides`.

12. In `crates/ruff_linter/src/settings/types.rs`, apply the required changes. Makes `FilePatternSet` implement `Clone` to support cloning of `Configuration` objects needed for override layering.

13. In `crates/ruff_wasm/src/lib.rs`, update `Workspace.new`. Updates the WASM `Workspace::new` to pass `Some(Path::new("."))` to `Configuration::from_options`.

14. In `crates/ruff_workspace/src/configuration.rs`, update `Configuration.from_options` and `warn_about_deprecated_top_level_lint_options`. Updates `Configuration::from_options` to accept an optional `project_root` parameter, enabling override configurations (which have no file path) to resolve relative paths correctly.

15. In `crates/ruff_workspace/src/options.rs`, apply the required changes. Derives `Clone` on all 29 option structs (`Options`, `LintCommonOptions`, `Flake8AnnotationsOptions`, etc.) to support cloning `Configuration` for override merging.

16. In `crates/ruff_workspace/src/resolver.rs`, update `resolve_configuration`. Updates `resolve_root_settings` to accept `ConfigArguments` instead of separate parameters.