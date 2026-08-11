# Allow override of configuration options via the CLI

Currently, Ruff includes many configuration options that are only available via a configuration file. These options should be available via the CLI as well so users can either:

- Provide configuration options without defining a configuration file
- Override configuration options per invocation of Ruff without modifying files

There have been previous requests for this, but I could not find them. If you know where they're at please share so we can have more historical context here.

## Proposals

There are a few options for exposing this capability.

**Environment variables**

Add environment variable overrides for all settings. Environment variables would take precedence over all persistent configuration options but not CLI flags.

**A repeatable CLI option with key value pairs**

A  CLI option for overriding settings e.g. `--setting <NAME>=<VALUE>`

Alternative names include `--settings`, `--override-setting`, `--override-config`, `--set-config`, `--configure`, `--override`, `--option`, `--options`

> Ruff already uses `--config <CONFIG>` to provide a path to a configuration file.
> Cargo uses `--config` for both overriding options _and_ providing the path to a configuration file.

**A CLI option with JSON support**

A  CLI option for overriding settings in bulk e.g. `--settings {...}`

This has been requested for programmatic use of Ruff previously e.g. you can use `jq` to pass a configuration file in bulk. However, this is not a very user-friendly approach for most use cases.

**Dedicated CLI options**

A dedicated CLI option generated for each setting e.g. `--set-<name> VALUE`.

We would probably omit enumerating these in the `help` menus and document the pattern instead. We could omit the `set-` prefix but then we need to worry about collisions between configuration options and existing CLI flags. Additionally, this option does not work well with the `<section>.<name>` syntax used in our configuration.
