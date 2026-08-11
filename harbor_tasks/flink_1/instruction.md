You are working in `/workspace/flink`, a source tree checked out at
the base commit for this task. Implement the requested behavior in the source
tree, then run:

```bash
lolbench-submit
```

Do not stop after editing files, running tests, or describing the solution. The
task is complete only when `lolbench-submit` has created
`/logs/artifacts/solution.patch`. If that file does not exist, continue
working and run `lolbench-submit` again.

That command writes your implementation diff to
`/logs/artifacts/solution.patch`, which is the artifact the Harbor verifier
will grade. Before running `lolbench-submit`, clean or revert any test files
you created or modified; test files must not be included in the final
`solution.patch`.

This environment has no outbound internet access — `curl`/`wget`, `git fetch`/`clone`, package installs, and web fetch/search will all fail. Implement the requirements using only the code already in the workspace and your own knowledge; do not attempt to fetch or search external resources.

Now please implement the following requirements in the source tree:

---

# FLIP-77: Introduce ConfigOptions with Data Types

Please keep the discussion on the mailing list rather than commenting on the wiki (wiki discussions get unwieldy fast).

# Motivation

`ConfigOption` and `Configuration` are crucial parts of the Flink project because every component in the stack needs possibilities of parameterization.

Ideally, every parameterization should also be **persistable in a config file** and **changeable programmatically** or **specified in a CLI session via string properties**.

If one takes a look at the currently defined config options, there are many inconsistencies and shortcomings such as:

  * A user does not know the expected data type of an option or allowed values. If the description is not good enough, an option is difficult to configure.
  * Many components have implemented custom parsing logic to perform common tasks such as list splitting or duration parsing.
  * List separators are not used consistently: sometimes comma sometimes semicolon.
  * Parsing of durations uses Scala classes.
  * There is no concept of optional properties which means implementers come up with "fallback" values such as "parallelism of -1" means fallback to parallelism defined in flink-conf.yaml.

Currently, classes such as `o.a.f.table.descriptors.DescriptorProperties` are symptoms of the root cause of missing functionality in Flink's configuration capabilities.

We should evolve ConfigOption and Configuration to replace DescriptorProperties and have a unified configuration for Flink from higher levels (e.g. SQL Client CLI) over core classes (e.g. new Executor) down to connectors (e.g. Kafka with JSON format).

# Public Interfaces

List of new interfaces:

  * `OptionBuilder#intType(...)/stringType(...)/...`
  * `TypedConfigOptionBuilder`, `ListConfigOptionBuilder`
  * `ReadableConfig` / `WritableConfig`
  * `Configuration` implements `ReadableConfig` / `WritableConfig` thus receives new `get(...)` / `getOptional(...)` / `set(...)`

# Proposed Changes

## Overview

Because config options are already used at a couple of places in the code base, we aimed to minimize the amount of changes necessary while enriching a config option with more declarative information.

The declarative approach of ConfigOptions and the clear separation of Java classes and ReadableConfig/WritableConfig allows us to change the actual string serialization format at any time. Thus, we can still introduce pure YAML or JSON in the future.

Example:

    ConfigOptions.key("key")
    .intType()
    .defaultValue(12);

### Proposed changes to ConfigOption:

In order for ConfigOption to contain information about the class it describes, we should add two additional fields to ConfigOption:

` private final Class typeClass;`

` private final boolean isList;`

The typeClass field describes the type that this ConfigOption describes. There are 3 cases:

  * typeClass == e.g. Integer.class -> ConfigOption<Integer>
  * typeClass == e.g. Integer.class & isList = true for ConfigOption<List<Integer>>
  * typeClass == Map.class -> ConfigOption<Map<String, String>>

This way we can describe all necessary types without backwards incompatible changes to the ConfigOption class.

_We explicitly exclude further nesting_. This could potentially circumvent the current configuration design which is not what we want.

However, lists of data types or a string-string map are frequently needed types.

### Proposed New Builder Pattern:

The current builder pattern in ConfigOptions is not expressive enough to define a type or a list of types. We suggest to introduce a new builder that can be accessed via:

    ConfigOptions.key("key")

The entire builder is defined as:

    public static class OptionBuilder {
            private final String key;

            OptionBuilder(String key) {
                this.key = key;
            }

            TypedConfigOptionBuilder<Integer> intType() {
                return new TypedConfigOptionBuilder<>(key, Integer.class);
            }

            TypedConfigOptionBuilder<String> stringType() {
                return new TypedConfigOptionBuilder<>(key, String.class);
            }

            TypedConfigOptionBuilder<Duration> durationType() {
                return new TypedConfigOptionBuilder<>(key, Duration.class);
            }

            TypedConfigOptionBuilder<Map<String, String>> mapType() {
                return new TypedConfigOptionBuilder<>(key, Map.class);
            }

            <T> TypedConfigOptionBuilder<T> enumType(Class<T extends Enum<T>> clazz) {
                return new TypedConfigOptionBuilder<>(key, clazz);
            }

            // All supported atomic types: Boolean, Integer, Long, Double, Float, String, Duration, MemorySize, Enum, Map<String, String>

            /**
             * Creates a ConfigOption with the given default value.
             *
             * <p>This method does not accept "null". For options with no default value, choose
             * one of the {@code noDefaultValue} methods.
             *
             * @param value The default value for the config option
             * @param <T> The type of the default value.
             * @return The config option with the default value.
             */
            @Deprecated
            public <T> ConfigOption<T> defaultValue(T value) {
                checkNotNull(value);
                return new ConfigOption<>(key, value);
            }

            /**
             * Creates a string-valued option with no default value.
             * String-valued options are the only ones that can have no
             * default value.
             *
             * @return The created ConfigOption.
             */
            @Deprecated
            public ConfigOption<String> noDefaultValue() {
                return new ConfigOption<>(key, null);
            }

        }

        public static class TypedConfigOptionBuilder<T> {
            private final String key;
            private final Class clazz;

            TypedConfigOptionBuilder(String key, Class clazz) {
                this.key = key;
                this.clazz = clazz;
            }

            public ListConfigOptionBuilder<T> asList() {
                return new ListConfigOptionBuilder<>(key, clazz);
            }

            public ConfigOption<T> defaultValue(T value) {
                return new ConfigOption<>(
                    key,
                    clazz,
                    false,
                    Description.builder().text("").build(),
                    value,
                    EMPTY);
            }

            public ConfigOption<T> noDefaultValue() {
                return new ConfigOption<>(
                    key,
                    clazz,
                    false,
                    Description.builder().text("").build(),
                    null,
                    EMPTY);
            }
        }

        public static class ListConfigOptionBuilder<T> {
            private final String key;
            private final Class clazz;

            ListConfigOptionBuilder(String key, Class clazz) {
                this.key = key;
                this.clazz = clazz;
            }

            @SafeVarargs
            public final ConfigOption<List<T>> defaultValues(T... values) {
                return new ConfigOption<>(
                    key,
                    clazz,
                    true,
                    Description.builder().text("").build(),
                    Arrays.asList(values),
                    EMPTY);
            }

            public ConfigOption<List<T>> noDefaultValue() {
                return new ConfigOption<>(
                    key,
                    clazz,
                    true,
                    Description.builder().text("").build(),
                    null,
                    EMPTY);
            }
        }

We will deprecate two methods on `OptionBuilder#noDefaultValue` & `OptionBuilder#defaultValue` as they do not define the option type properly.

### Proposed changes to Configuration:

We suggest to introduce new interfaces & make Configuration extend from it:

`interface ReadableConfig {`

` T get(ConfigOption<T> configOption);`

` Optional<T> getOptional(ConfigOption<T> configOption);`

`}`

We will not support nullability but we distinguish between an option that is present or not. This is necessary e.g. for handling fallback options. Those would return `Optional.empty()` in case the backing map does not contain the given key, or the value of the given key is null.

`interface WritableConfig {`

` WritableConfig set(ConfigOption<T> configOption, T value)`

`}`

`class Configuration implements ReadableConfig, WritableConfig`

Note: Currently, Configuration also includes parser functionality. This might change in the future. Ideally, Configuration should only contain the parsed Object's for efficiency reasons.

**However, because ConfigOptions need to be parsed from a file or CLI session property, we need to define a string format for all data types.**

#### Deprecate write(DataOutputView)/read(DataInputView)

Those methods are used only when dealing with IOReadableWritable. In case of Configuration class this interface is not used. It can not be removed though because it is part of a Public interface. We suggest, though, to clearly mention that it is no longer supported and throw exceptions for the newly introduced types of ConfigOption.

## List Options

We suggest adding the possibility of lists.

We suggest using a semicolon for lists. For escaping list elements, they can be surrounded by single quotes or double quotes for escaping reserved characters and leading/trailing whitespace. Two following quotes escape the quote itself.

### Example:

    public static final ConfigOption<List<String>> PATHS =
        ConfigOption.key("paths")
            .stringType()
            .asList()
            .defaultValue(List.of("/usr/bin", "/tmp/bin"));

The string representation of those examples would look like:

`paths: /usr/bin;/tmp/bin
`

`escaped_paths: "/usr/path;1" ; '/usr/path''s;2' ; /usr/path3`

### Rejected Alternatives:

**Alternative 1:**

` cached-files.0=a0`

`cached-files.1=a1`

Pros:

\- already used in DescriptorProperties

\- easy to define manually

Cons:

\- Users need to keep track of the indices

\- The key space is not constant. Validation of keys would require prefix magic and wildcards. Like in TableFactories: `cached-files.#.file.*`

\- An object spans multiple keys and cannot be set in one CLI `SET` command.

**Alternative 2:**

` cached-files=[a0,a1]`

Pros:

\- Uses the JSON standard

\- easy to define manually

\- entire (nested) object under a common key

Cons:

\- opens the gate for complex nested configuration that is hard to validate and to document.

\- Problems with escaping but little because defined by the JSON standard.

## Duration Options

We suggest to add native support for ConfigOption<java.time.Duration>:

`ConfigOption<Duration> option = ...`

`Duration size = conf.get(option)
`

The built-in string format of java.time.Duration (e.g. PT0.020S for “20ms”) is not user friendly and really hard to specify manually. Therefore we suggest to introduce custom parsing logic for string representation. We suggest to add a logic that allows for writing the duration value and unit in which it is given, e.g. 20ms. But at the same time we should also support the original format.

The format should look like “d+w*[unit]”, where unit is one of [“ns”, “us”, “ms”, “s”, “m”, “min”, “h”, “d”]. Whitespaces are ignored. We will use and extend `org.apache.flink.util.TimeUtils` for this purposes.

## Memory Size Options

We should add native support for ConfigOption<MemorySize>:

`ConfigOption<MemorySize> option = ...`

`MemorySize size = conf.get(option)`

For the string representation we would reuse the parsing logic from new MemorySize().

The format is as follows “d+ [unit]”, where unit is one of [“b”, “bytes”, “k”, “kb”, "kibibytes", "m", "mb", "mebibytes", "g", "gb", "gibibytes", "t", "tb", "tebibytes"].

## Map Options

We suggest introducing properties ConfigOption type to support a map of custom string properties. The same escaping logic as for lists applies.

ConfigOption<Map<String, String>> option = ....

Map<String, String> properties = conf.get(option)

We suggest to use the following string format:

exec.global-job-parameters = key1:value1, key2:value2, key3:value3

We use comma for separation of entries as it is weaker than the semicolon for lists. It is possible to have a list of maps.

## Documentation changes

We suggest to extend the documentation generator with Type column that will describe the expected type.

| Key | Type | Default | Description |
|---|---|---|---|
| key1 | MemorySize | (none) | description of key1 |
| key2 | MemorySize | 1024m | description of key2 |

# Compatibility, Deprecation, and Migration Plan

  * All existing config options are still valid and have no changed behavior, with one exception: the typed accessors `Configuration#getClass` and `Configuration#getBytes` now reject an unrecognized or unconvertible value by throwing an `IllegalArgumentException` instead of logging a warning and returning the provided default
  * Deprecate the Configuration#write(DataOutputView)/read(DataInputView) as they are effectively not used.
  * Deprecate ConfigOption#defaultValue(...)/noDefaultValue

# Implementation Plan

Each feature section can be a separate commit or issue. Such as:

  * New typed ConfigOption with builder pattern
  * Lists
  * Duration
  * Memory Size

# Rejected Alternatives

See corresponding feature sections.
