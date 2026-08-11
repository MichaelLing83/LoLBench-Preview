# Ruff - Issue-8368: Allow override of configuration options via the CLI (PR #9599)

**PR:** https://github.com/astral-sh/ruff/pull/9599
**Requirement Doc:** https://github.com/astral-sh/ruff/issues/8368

## Matching Statistics
- **Requirement Doc Coverage:** 1/1 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 16/21 files mapped (76.2%) + 5/21 files associated (23.8%) = 21/21 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | Allow override of configuration options via the CLI | No | N/A | knowledge |
| 2 | Allow override of configuration options via the CLI > Proposals | Yes | Yes | implementation |


### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `Cargo.lock` | vendor | — | Section 2 |
| 2 | `crates/ruff/Cargo.toml` | build | — | Section 2 |
| 3 | `crates/ruff/src/args.rs` | source | Section 2 | — |
| 4 | `crates/ruff/src/commands/add_noqa.rs` | source | Section 2 | — |
| 5 | `crates/ruff/src/commands/check.rs` | source | Section 2 | — |
| 6 | `crates/ruff/src/commands/check_stdin.rs` | source | Section 2 | — |
| 7 | `crates/ruff/src/commands/format.rs` | source | Section 2 | — |
| 8 | `crates/ruff/src/commands/format_stdin.rs` | source | Section 2 | — |
| 9 | `crates/ruff/src/commands/show_files.rs` | source | Section 2 | — |
| 10 | `crates/ruff/src/commands/show_settings.rs` | source | Section 2 | — |
| 11 | `crates/ruff/src/lib.rs` | source | Section 2 | — |
| 12 | `crates/ruff/src/resolve.rs` | source | Section 2 | — |
| 13 | `crates/ruff/tests/format.rs` | test | — | Section 2 |
| 14 | `crates/ruff/tests/lint.rs` | test | — | Section 2 |
| 15 | `crates/ruff_dev/src/format_dev.rs` | source | Section 2 | — |
| 16 | `crates/ruff_linter/src/settings/types.rs` | source | Section 2 | — |
| 17 | `crates/ruff_wasm/src/lib.rs` | source | Section 2 | — |
| 18 | `crates/ruff_workspace/src/configuration.rs` | source | Section 2 | — |
| 19 | `crates/ruff_workspace/src/options.rs` | source | Section 2 | — |
| 20 | `crates/ruff_workspace/src/resolver.rs` | source | Section 2 | — |
| 21 | `docs/configuration.md` | documentation | — | Section 2 |

---

## Section 2: Proposals
*Path: Allow override of configuration options via the CLI > Proposals*
*Classification: Implementable*

> There are a few options for exposing this capability.
>
> **Environment variables**
>
> Add environment variable overrides for all settings. Environment variables would take precedence over all persistent configuration options but not CLI flags.
>
> **A repeatable CLI option with key value pairs**
>
> A  CLI option for overriding settings e.g. `--setting <NAME>=<VALUE>`
>
> Alternative names include `--settings`, `--override-setting`, `--override-config`, `--set-config`, `--configure`, `--override`, `--option`, `--options`
>
> > Ruff already uses `--config <CONFIG>` to provide a path to a configuration file.
> > Cargo uses `--config` for both overriding options _and_ providing the path to a configuration file.
>
> **A CLI option with JSON support**
>
> A  CLI option for overriding settings in bulk e.g. `--settings {...}`
>
> This has been requested for programmatic use of Ruff previously e.g. you can use `jq` to pass a configuration file in bulk. However, this is not a very user-friendly approach for most use cases.
>
> **Dedicated CLI options**
>
> A dedicated CLI option generated for each setting e.g. `--set-<name> VALUE`.
>
> We would probably omit enumerating these in the `help` menus and document the pattern instead. We could omit the `set-` prefix but then we need to worry about collisions between configuration options and existing CLI flags. Additionally, this option does not work well with the `<section>.<name>` syntax used in our configuration.

#### Requirement Summary
The section proposes four approaches for CLI configuration overrides: environment variables, repeatable key-value CLI option, JSON support, and dedicated CLI flags. The PR implements the "repeatable CLI option with key value pairs" approach, extending the existing `--config` flag to accept either a config file path or inline TOML `KEY=VALUE` overrides. Adds `ConfigArguments`/`ConfigArgumentParser` types, updates all command modules, and rewrites CLI documentation.

**File proportion:** 16/21 files mapped (76.2%) + 5/21 files associated (23.8%) = 21/21 accounted (100.0%)
#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `crates/ruff/src/args.rs` | Modified | +397 / -127 | `CheckCommand`, `FormatCommand`, `ConfigArguments`, `ConfigurationTransformer`, `TomlParseFailureKind`, `TomlParseFailure`, `SingleConfigArgument`, `ConfigArgumentParser`, `ValueParserFactory`, `TypedValueParser`, `CheckArguments`, `FormatArguments`, `CliOverrides`, `ExplicitConfigOverrides` | `ConfigArguments.config_file`, `ConfigArguments.from_cli_arguments`, `ConfigurationTransformer.transform`, `CheckCommand.partition`, `FormatCommand.partition`, `TomlParseFailureKind.fmt`, `TomlParseFailure.fmt`, `ValueParserFactory.value_parser`, `TypedValueParser.parse_ref` |
| `crates/ruff/src/commands/add_noqa.rs` | Modified | +3 / -3 | — | `add_noqa` |
| `crates/ruff/src/commands/check.rs` | Modified | +5 / -5 | — | `check`, `unreadable_files` |
| `crates/ruff/src/commands/check_stdin.rs` | Modified | +2 / -2 | — | `check_stdin` |
| `crates/ruff/src/commands/format.rs` | Modified | +4 / -5 | — | `format` |
| `crates/ruff/src/commands/format_stdin.rs` | Modified | +7 / -5 | — | `format_stdin` |
| `crates/ruff/src/commands/show_files.rs` | Modified | +3 / -3 | — | `show_files` |
| `crates/ruff/src/commands/show_settings.rs` | Modified | +3 / -3 | — | `show_settings` |
| `crates/ruff/src/lib.rs` | Modified | +24 / -15 | — | `format`, `check` |
| `crates/ruff/src/resolve.rs` | Modified | +9 / -9 | — | `resolve` |
| `crates/ruff_dev/src/format_dev.rs` | Modified | +8 / -9 | — | `parse_cli`, `find_pyproject_config`, `ruff_check_paths` |
| `crates/ruff_linter/src/settings/types.rs` | Modified | +1 / -1 | — | — |
| `crates/ruff_wasm/src/lib.rs` | Modified | +3 / -2 | `Workspace` | `Workspace.new` |
| `crates/ruff_workspace/src/configuration.rs` | Modified | +19 / -8 | `Configuration` | `Configuration.from_options`, `warn_about_deprecated_top_level_lint_options` |
| `crates/ruff_workspace/src/options.rs` | Modified | +29 / -29 | — | — |
| `crates/ruff_workspace/src/resolver.rs` | Modified | +1 / -1 | — | `resolve_configuration` |

#### Modification Summary
- **`crates/ruff/src/args.rs`**: Core implementation of the dual-purpose `--config` flag. Adds `SingleConfigArgument` enum distinguishing file paths from inline TOML overrides. Adds `ConfigArgumentParser` that parses each `--config` value: if it contains `=` and parses as valid TOML, it is treated as an override; otherwise it is treated as a config file path. Adds `ConfigArguments` struct (replacing `CliOverrides`) that holds both the optional config file path and a vector of `Configuration` overrides. Adds `TomlParseFailure` / `TomlParseFailureKind` for error reporting. Validates that at most one config file is specified and that overrides use the correct TOML prefix (`[tool.ruff]` keys use bare names, `pyproject.toml` keys require `tool.ruff.` prefix).
- **`crates/ruff/src/lib.rs`**: Updates the top-level `check` and `format` entry points to accept `ConfigArguments` instead of separate `config: Option<PathBuf>` and `overrides: CliOverrides` parameters. Constructs the `ConfigArguments` from clap-parsed arguments.
- **`crates/ruff/src/resolve.rs`**: Updates `resolve()` to accept `ConfigArguments` and apply the override `Configuration` objects on top of the file-based configuration, in order. Each override is merged via `Configuration::combine()`.
- **`check.rs`, `check_stdin.rs`, `format.rs`, `format_stdin.rs`, `add_noqa.rs`, `show_files.rs`, `show_settings.rs`**: All command modules rename imports from `CliOverrides` to `ConfigArguments` and update function signatures/calls accordingly. `format.rs` and `format_stdin.rs` additionally remove the separate `config` parameter from their `resolve()` calls.
- **`crates/ruff_dev/src/format_dev.rs`**: Updates the dev format tool's `parse_cli()` to use `ConfigArguments::default()` instead of the old `CliOverrides`.
- **`crates/ruff_linter/src/settings/types.rs`**: Makes `FilePatternSet` implement `Clone` to support cloning of `Configuration` objects needed for override layering.
- **`crates/ruff_wasm/src/lib.rs`**: Updates the WASM `Workspace::new()` to pass `Some(Path::new("."))` to `Configuration::from_options()`.
- **`crates/ruff_workspace/src/configuration.rs`**: Updates `Configuration::from_options()` to accept an optional `project_root` parameter, enabling override configurations (which have no file path) to resolve relative paths correctly.
- **`crates/ruff_workspace/src/options.rs`**: Derives `Clone` on all 29 option structs (`Options`, `LintCommonOptions`, `Flake8AnnotationsOptions`, etc.) to support cloning `Configuration` for override merging.
- **`crates/ruff_workspace/src/resolver.rs`**: Updates `resolve_root_settings()` to accept `ConfigArguments` instead of separate parameters.
- **`crates/ruff/src/commands/add_noqa.rs`**: Implements changes for this section.
- **`crates/ruff/src/commands/check.rs`**: Implements changes for this section.
- **`crates/ruff/src/commands/check_stdin.rs`**: Implements changes for this section.
- **`crates/ruff/src/commands/format.rs`**: Implements changes for this section.
- **`crates/ruff/src/commands/format_stdin.rs`**: Implements changes for this section.
- **`crates/ruff/src/commands/show_files.rs`**: Implements changes for this section.
- **`crates/ruff/src/commands/show_settings.rs`**: Implements changes for this section.
---

#### Associated Changes
| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `Cargo.lock` | Modified | +1 / -0 | Lock file updated for toml crate dependency | — | — |
| `crates/ruff/Cargo.toml` | Modified | +1 / -0 | Build dependency: adds the `toml` workspace dependency needed by `args.rs` to parse inline `KEY=VALUE` overrides; not a behavioral requirement of this section | — | — |
| `docs/configuration.md` | Modified | +72 / -9 | Documentation: rewrites the "Command-line interface" section to document the dual-purpose `--config` flag, inline `KEY=VALUE` syntax, and precedence; documents but does not implement the requirement | — | — |
| `crates/ruff/tests/format.rs` | Modified | +173 / -0 | Integration tests for --config override with format command | — | — |
| `crates/ruff/tests/lint.rs` | Modified | +335 / -0 | Integration tests for --config override with lint command | — | — |
---


---

## Unmapped Requirement Sections

None

## Unmapped PR Files

None
