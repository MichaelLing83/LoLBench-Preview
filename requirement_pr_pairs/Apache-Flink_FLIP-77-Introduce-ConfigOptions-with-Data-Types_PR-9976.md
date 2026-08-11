# Apache Flink - FLIP-77: Introduce ConfigOptions with Data Types

**PR:** https://github.com/apache/flink/pull/9976
**Requirement Doc:** https://cwiki.apache.org/confluence/display/FLINK/FLIP-77

## Matching Statistics
- **Requirement Doc Coverage:** 9/9 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 12/13 files mapped (92.3%) + 1/13 files associated (7.7%) = 13/13 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | FLIP-77: Introduce ConfigOptions with Data Types | No | N/A | knowledge |
| 2 | Motivation | No | N/A | contextual |
| 3 | Public Interfaces | No | N/A | knowledge |
| 4 | Proposed Changes | No | N/A | knowledge |
| 5 | Proposed Changes > Overview | No | N/A | knowledge |
| 6 | Proposed Changes > Overview > Proposed changes to ConfigOption: | Yes | Yes | implementation |
| 7 | Proposed Changes > Overview > Proposed New Builder Pattern: | Yes | Yes | implementation |
| 8 | Proposed Changes > Overview > Proposed changes to Configuration: | Yes | Yes | implementation |
| 9 | Proposed Changes > Overview > Proposed changes to Configuration: > Deprecate write(DataOutputView)/read(DataInputView) | Yes | Yes | implementation |
| 10 | Proposed Changes > List Options | Yes | Yes | implementation |
| 11 | Proposed Changes > List Options > Example: | No | N/A | knowledge |
| 12 | Proposed Changes > List Options > Rejected Alternatives: | No | N/A | contextual |
| 13 | Proposed Changes > Duration Options | Yes | Yes | implementation |
| 14 | Proposed Changes > Memory Size Options | Yes | Yes | implementation |
| 15 | Proposed Changes > Map Options | Yes | Yes | implementation |
| 16 | Proposed Changes > Documentation changes | No | N/A | knowledge |
| 17 | Compatibility, Deprecation, and Migration Plan | No | N/A | contextual |
| 18 | Implementation Plan | No | N/A | knowledge |
| 19 | Test Plan | Yes | Yes | evaluation |
| 20 | Rejected Alternatives | No | N/A | contextual |

### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `flink-core/src/main/java/org/apache/flink/configuration/ConfigOption.java` | source | Section 6 | — |
| 2 | `flink-core/src/main/java/org/apache/flink/configuration/ConfigOptions.java` | source | Section 7, Section 10, Section 13, Section 14, Section 15 | — |
| 3 | `flink-core/src/main/java/org/apache/flink/configuration/Configuration.java` | source | Section 8, Section 9, Section 10, Section 13, Section 14, Section 15 | — |
| 4 | `flink-core/src/main/java/org/apache/flink/configuration/DelegatingConfiguration.java` | source | — | Section 8 |
| 5 | `flink-core/src/main/java/org/apache/flink/configuration/ReadableConfig.java` | source | Section 8 | — |
| 6 | `flink-core/src/main/java/org/apache/flink/configuration/StructuredOptionsSplitter.java` | source | Section 10, Section 15 | — |
| 7 | `flink-core/src/main/java/org/apache/flink/configuration/WritableConfig.java` | source | Section 8 | — |
| 8 | `flink-core/src/test/java/org/apache/flink/configuration/ConfigurationConversionsTest.java` | test | Section 19 | — |
| 9 | `flink-core/src/test/java/org/apache/flink/configuration/ConfigurationParsingInvalidFormatsTest.java` | test | Section 19 | — |
| 10 | `flink-core/src/test/java/org/apache/flink/configuration/ConfigurationTest.java` | test | Section 19 | — |
| 11 | `flink-core/src/test/java/org/apache/flink/configuration/ReadableWritableConfigurationTest.java` | test | Section 19 | — |
| 12 | `flink-core/src/test/java/org/apache/flink/configuration/StructuredOptionsSplitterTest.java` | test | Section 19 | — |
| 13 | `flink-core/src/test/java/org/apache/flink/configuration/UnmodifiableConfigurationTest.java` | test | Section 19 | — |

---

## Section 6: Proposed changes to ConfigOption:
*Path: Proposed Changes > Overview > Proposed changes to ConfigOption:*
*Classification: Implementable*

> In order for ConfigOption to contain information about the class it describes, we should add two additional fields to ConfigOption:
>
> ` private final Class typeClass;`
>
> ` private final boolean isList;`
>
> The typeClass field describes the type that this ConfigOption describes. There are 3 cases:
>
>   * typeClass == e.g. Integer.class -> ConfigOption<Integer>
>   * typeClass == e.g. Integer.class & isList = true for ConfigOption<List<Integer>>
>   * typeClass == Map.class -> ConfigOption<Map<String, String>>
>
> This way we can describe all necessary types without backwards incompatible changes to the ConfigOption class.
>
> _We explicitly exclude further nesting_. This could potentially circumvent the current configuration design which is not what we want.
>
> However, lists of data types or a string-string map are frequently needed types.

#### Requirement Summary
This section specifies adding `typeClass` and `isList` fields to `ConfigOption` to encode the type information at the option declaration level, covering three cases: atomic types, list types, and map types. The PR implements these fields in `ConfigOption.java`, refactoring the constructors to accept `Class` and `boolean isList` parameters and adding an `EMPTY_DESCRIPTION` constant.

**File proportion:** 1/13 files mapped (7.7%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-core/src/main/java/org/apache/flink/configuration/ConfigOption.java` | Modified | +34 / -32 | `ConfigOption` | `ConfigOption.ConfigOption`, `ConfigOption.getClazz`, `ConfigOption.isList`, `ConfigOption.withFallbackKeys`, `ConfigOption.withDeprecatedKeys`, `ConfigOption.withDescription`, `ConfigOption.hasDeprecatedKeys` |

#### Modification Summary
- **`flink-core/src/main/java/org/apache/flink/configuration/ConfigOption.java`**: Adds the `typeClass` (Class) and `isList` (boolean) fields as specified, refactors the constructors to accept these new parameters, and adds an `EMPTY_DESCRIPTION` constant. The three cases (atomic, list, map) are documented in the field Javadoc exactly as described in the requirement.

---

## Section 7: Proposed New Builder Pattern:
*Path: Proposed Changes > Overview > Proposed New Builder Pattern:*
*Classification: Implementable*

> The current builder pattern in ConfigOptions is not expressive enough to define a type or a list of types. We suggest to introduce a new builder that can be accessed via:
>
>     ConfigOptions.key("key")
>
> The entire builder is defined as:
>
>     public static class OptionBuilder {
>        	 private final String key;
>
>        	 OptionBuilder(String key) {
>        		 this.key = key;
>        	 }
>
>        	 TypedConfigOptionBuilder<Integer> intType() {
>        		 return new TypedConfigOptionBuilder<>(key, Integer.class);
>        	 }
>
>        	 TypedConfigOptionBuilder<String> stringType() {
>        		 return new TypedConfigOptionBuilder<>(key, String.class);
>        	 }
>
>        	 TypedConfigOptionBuilder<Duration> durationType() {
>        		 return new TypedConfigOptionBuilder<>(key, Duration.class);
>        	 }
>
>        	 TypedConfigOptionBuilder<Map<String, String>> mapType() {
>        		 return new TypedConfigOptionBuilder<>(key, Map.class);
>        	 }
>
>        	 <T> TypedConfigOptionBuilder<T> enumType(Class<T extends Enum<T>> clazz) {
>        		 return new TypedConfigOptionBuilder<>(key, clazz);
>        	 }
>
>        	 // All supported atomic types: Boolean, Integer, Long, Double, Float, String, Duration, MemorySize, Enum, Map<String, String>
>
>         	/**
>        	  * Creates a ConfigOption with the given default value.
>        	  *
>        	  * <p>This method does not accept "null". For options with no default value, choose
>        	  * one of the {@code noDefaultValue} methods.
>        	  *
>        	  * @param value The default value for the config option
>        	  * @param <T> The type of the default value.
>        	  * @return The config option with the default value.
>        	  */
>        	 @Deprecated
>        	 public <T> ConfigOption<T> defaultValue(T value) {
>        		 checkNotNull(value);
>        		 return new ConfigOption<>(key, value);
>        	 }
>
>        	 /**
>        	  * Creates a string-valued option with no default value.
>        	  * String-valued options are the only ones that can have no
>        	  * default value.
>        	  *
>        	  * @return The created ConfigOption.
>        	  */
>        	 @Deprecated
>        	 public ConfigOption<String> noDefaultValue() {
>        		 return new ConfigOption<>(key, null);
>        	 }
>
>         }
>
>         public static class TypedConfigOptionBuilder<T> {
>        	 private final String key;
>        	 private final Class clazz;
>
>        	 TypedConfigOptionBuilder(String key, Class clazz) {
>        		 this.key = key;
>        		 this.clazz = clazz;
>        	 }
>
>        	 public ListConfigOptionBuilder<T> asList() {
>        		 return new ListConfigOptionBuilder<>(key, clazz);
>        	 }
>
>        	 public ConfigOption<T> defaultValue(T value) {
>        		 return new ConfigOption<>(
>        			 key,
>        			 clazz,
>        			 false,
>        			 Description.builder().text("").build(),
>        			 value,
>        			 EMPTY);
>        	 }
>
>        	 public ConfigOption<T> noDefaultValue() {
>        		 return new ConfigOption<>(
>        			 key,
>        			 clazz,
>        			 false,
>        			 Description.builder().text("").build(),
>        			 null,
>        			 EMPTY);
>        	 }
>         }
>
>         public static class ListConfigOptionBuilder<T> {
>        	 private final String key;
>        	 private final Class clazz;
>
>        	 ListConfigOptionBuilder(String key, Class clazz) {
>        		 this.key = key;
>        		 this.clazz = clazz;
>        	 }
>
>        	 @SafeVarargs
>        	 public final ConfigOption<List<T>> defaultValues(T... values) {
>        		 return new ConfigOption<>(
>        			 key,
>        			 clazz,
>        			 true,
>        			 Description.builder().text("").build(),
>        			 Arrays.asList(values),
>        			 EMPTY);
>        	 }
>
>        	 public ConfigOption<List<T>> noDefaultValue() {
>        		 return new ConfigOption<>(
>        			 key,
>        			 clazz,
>        			 true,
>        			 Description.builder().text("").build(),
>        			 null,
>        			 EMPTY);
>        	 }
>         }
>
> We will deprecate two methods on `OptionBuilder#noDefaultValue` & `OptionBuilder#defaultValue` as they do not define the option type properly.

#### Requirement Summary
This section specifies a new builder pattern in `ConfigOptions` with `OptionBuilder` providing typed factory methods (`intType()`, `stringType()`, `durationType()`, `mapType()`, `enumType()`), `TypedConfigOptionBuilder<T>` with `defaultValue()`/`noDefaultValue()`/`asList()`, and `ListConfigOptionBuilder<T>` with `defaultValues()`/`noDefaultValue()`. It also calls for deprecating the old untyped `OptionBuilder#defaultValue` and `OptionBuilder#noDefaultValue`. The PR implements all three builder classes in `ConfigOptions.java` and marks the old methods `@Deprecated`.

**File proportion:** 1/13 files mapped (7.7%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-core/src/main/java/org/apache/flink/configuration/ConfigOptions.java` | Modified | +203 / -2 | `OptionBuilder`, `ConfigOptions`, `TypedConfigOptionBuilder` | `OptionBuilder.booleanType`, `OptionBuilder.intType`, `OptionBuilder.longType`, `OptionBuilder.floatType`, `OptionBuilder.doubleType`, `OptionBuilder.stringType`, `OptionBuilder.enumType`, `OptionBuilder.defaultValue`, `OptionBuilder.noDefaultValue`, `TypedConfigOptionBuilder.TypedConfigOptionBuilder`, `TypedConfigOptionBuilder.defaultValue`, `TypedConfigOptionBuilder.noDefaultValue` |

#### Modification Summary
- **`flink-core/src/main/java/org/apache/flink/configuration/ConfigOptions.java`**: Implements the full builder hierarchy as specified: adds typed factory methods (`intType()`, `stringType()`, `booleanType()`, `longType()`, `floatType()`, `doubleType()`, `durationType()`, `memoryType()`, `mapType()`, `enumType()`) to `OptionBuilder`; adds the `TypedConfigOptionBuilder<T>` inner class with `defaultValue()`, `noDefaultValue()`, and `asList()` methods; adds `ListConfigOptionBuilder<T>` with `defaultValues()` and `noDefaultValue()`. The old untyped `OptionBuilder#defaultValue` and `OptionBuilder#noDefaultValue` methods are annotated `@Deprecated`.

---

## Section 8: Proposed changes to Configuration:
*Path: Proposed Changes > Overview > Proposed changes to Configuration:*
*Classification: Implementable*

> We suggest to introduce new interfaces & make Configuration extend from it:
>
> `interface ReadableConfig {`
>
> ` T get(ConfigOption<T> configOption);`
>
> ` Optional<T> getOptional(ConfigOption<T> configOption);`
>
> `}`
>
> We will not support nullability but we distinguish between an option that is present or not. This is necessary e.g. for handling fallback options. Those would return `Optional.empty()` in case the backing map does not contain the given key, or the value of the given key is null.
>
> `interface WritableConfig {`
>
> ` WritableConfig set(ConfigOption<T> configOption, T value)`
>
> `}`
>
> `class Configuration implements ReadableConfig, WritableConfig`
>
> Note: Currently, Configuration also includes parser functionality. This might change in the future. Ideally, Configuration should only contain the parsed Object's for efficiency reasons.
>
> **However, because ConfigOptions need to be parsed from a file or CLI session property, we need to define a string format for all data types.**

#### Requirement Summary
This section specifies the introduction of `ReadableConfig` and `WritableConfig` interfaces with `get()`/`getOptional()` and `set()` methods respectively, and making `Configuration` implement both interfaces. The PR adds the `ReadableConfig.java` and `WritableConfig.java` interface files and modifies `Configuration.java` to implement both, adding the `get()`, `getOptional()`, and `set()` methods with full type-aware parsing/conversion logic.

**File proportion:** 3/13 files mapped (23.1%) + 1/13 files associated (7.7%) = 4/13 accounted (30.8%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-core/src/main/java/org/apache/flink/configuration/ReadableConfig.java` | Added | +53 / -0 | `ReadableConfig` | `ReadableConfig.get`, `ReadableConfig.getOptional` |
| `flink-core/src/main/java/org/apache/flink/configuration/WritableConfig.java` | Added | +40 / -0 | `WritableConfig` | `WritableConfig.set` |
| `flink-core/src/main/java/org/apache/flink/configuration/Configuration.java` | Modified | +262 / -175 | `Configuration` | `Configuration.get`, `Configuration.getOptional`, `Configuration.set`, `Configuration.getRawValue`, `Configuration.getRawValueFromOption`, `Configuration.getValueOrDefaultFromOption`, `Configuration.convertValue`, `Configuration.convertToInt`, `Configuration.convertToString`, `Configuration.convertToLong`, `Configuration.convertToBoolean`, `Configuration.convertToFloat`, `Configuration.convertToDouble`, `Configuration.convertToEnum`, `Configuration.getClass`, `Configuration.getString`, `Configuration.getInteger`, `Configuration.getLong`, `Configuration.getBoolean`, `Configuration.getFloat`, `Configuration.getDouble`, `Configuration.getBytes`, `Configuration.getValue`, `Configuration.getEnum`, `Configuration.equals` |

#### Modification Summary
- **`flink-core/src/main/java/org/apache/flink/configuration/ReadableConfig.java`**: Adds the `ReadableConfig` interface with `get(ConfigOption<T>)` and `getOptional(ConfigOption<T>)` methods as specified, annotated `@PublicEvolving`.
- **`flink-core/src/main/java/org/apache/flink/configuration/WritableConfig.java`**: Adds the `WritableConfig` interface with `set(ConfigOption<T>, T)` method returning `WritableConfig` as specified, annotated `@PublicEvolving`.
- **`flink-core/src/main/java/org/apache/flink/configuration/Configuration.java`**: Modifies the class declaration to `implements ReadableConfig, WritableConfig` and adds implementations of `get()`, `getOptional()`, and `set()` methods with full type-aware parsing/conversion logic for all supported data types.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `flink-core/src/main/java/org/apache/flink/configuration/DelegatingConfiguration.java` | Modified | +20 / -1 | Must implement the new `ReadableConfig`/`WritableConfig` interface methods (`get`, `getOptional`, `set`) to conform to the interface contract as a Configuration delegate | `DelegatingConfiguration` | `DelegatingConfiguration.get`, `DelegatingConfiguration.getOptional`, `DelegatingConfiguration.set`, `DelegatingConfiguration.prefixOption` |

---

## Section 9: Deprecate write(DataOutputView)/read(DataInputView)
*Path: Proposed Changes > Overview > Proposed changes to Configuration: > Deprecate write(DataOutputView)/read(DataInputView)*
*Classification: Implementable*

> Those methods are used only when dealing with IOReadableWritable. In case of Configuration class this interface is not used. It can not be removed though because it is part of a Public interface. We suggest, though, to clearly mention that it is no longer supported and throw exceptions for the newly introduced types of ConfigOption.

#### Requirement Summary
This section specifies deprecating the `write(DataOutputView)` and `read(DataInputView)` methods on `Configuration` and throwing exceptions when encountering the newly introduced typed ConfigOptions during serialization. The PR implements this by adding exception-throwing logic in `read()` and `write()` for unrecognized types, with messages stating the method is deprecated.

**File proportion:** 1/13 files mapped (7.7%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-core/src/main/java/org/apache/flink/configuration/Configuration.java` | Modified | +262 / -175 | — | `Configuration.read`, `Configuration.write` |

#### Modification Summary
- **`flink-core/src/main/java/org/apache/flink/configuration/Configuration.java`**: `read(DataInputView)` and `write(DataOutputView)` are updated to throw exceptions for the newly introduced typed ConfigOption values, marking the legacy `IOReadableWritable` serialization path as deprecated per Section 9.

---

## Section 10: List Options
*Path: Proposed Changes > List Options*
*Classification: Implementable*

> We suggest adding the possibility of lists.
>
> We suggest using a semicolon for lists. For escaping list elements, they can be surrounded by single quotes or double quotes for escaping reserved characters and leading/trailing whitespace. Two following quotes escape the quote itself.

#### Requirement Summary
This section specifies adding list-type ConfigOption support with semicolon-delimited string representation and quoting/escaping logic (single or double quotes, with doubled quotes for escaping the quote character itself). The PR implements the `StructuredOptionsSplitter` class which provides the parsing and escaping logic, extends `ConfigOptions` with `asList()` on the builder, and adds list conversion logic in `Configuration`.

**File proportion:** 3/13 files mapped (23.1%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-core/src/main/java/org/apache/flink/configuration/StructuredOptionsSplitter.java` | Added | +176 / -0 | `StructuredOptionsSplitter`, `TokenType`, `Token` | `StructuredOptionsSplitter.processTokens`, `StructuredOptionsSplitter.tokenize`, `StructuredOptionsSplitter.consumeInQuotes`, `StructuredOptionsSplitter.consumeUnquoted`, `Token.Token`, `Token.getTokenType`, `Token.getString`, `Token.getPosition`, `StructuredOptionsSplitter.StructuredOptionsSplitter` |
| `flink-core/src/main/java/org/apache/flink/configuration/ConfigOptions.java` | Modified | +203 / -2 | `ListConfigOptionBuilder` | `TypedConfigOptionBuilder.asList`, `ListConfigOptionBuilder.ListConfigOptionBuilder`, `ListConfigOptionBuilder.defaultValues`, `ListConfigOptionBuilder.noDefaultValue` |
| `flink-core/src/main/java/org/apache/flink/configuration/Configuration.java` | Modified | +262 / -175 | — | `Configuration.convertToList` |

#### Modification Summary
- **`flink-core/src/main/java/org/apache/flink/configuration/StructuredOptionsSplitter.java`**: New utility class that implements the semicolon-delimited splitting with single/double quote escaping logic as specified. Handles the quoting rules where two consecutive quotes escape the quote itself.
- **`flink-core/src/main/java/org/apache/flink/configuration/ConfigOptions.java`**: Provides the `asList()` method on `TypedConfigOptionBuilder` and the `ListConfigOptionBuilder` class that enables defining list-typed config options.
- **`flink-core/src/main/java/org/apache/flink/configuration/Configuration.java`**: Adds list conversion/parsing logic in the `get()`/`getOptional()` methods, using `StructuredOptionsSplitter` to split string values into lists and convert each element to the target type.

---

## Section 13: Duration Options
*Path: Proposed Changes > Duration Options*
*Classification: Implementable*

> We suggest to add native support for ConfigOption<java.time.Duration>:
>
> `ConfigOption<Duration> option = ...`
>
> `Duration size = conf.get(option)  
> `
>
> The built-in string format of java.time.Duration (e.g. PT0.020S for “20ms”) is not user friendly and really hard to specify manually. Therefore we suggest to introduce custom parsing logic for string representation. We suggest to add a logic that allows for writing the duration value and unit in which it is given, e.g. 20ms. But at the same time we should also support the original format.
>
> The format should look like “d+w*[unit]”, where unit is one of [“ns”, “us”, “ms”, “s”, “m”, “min”, “h”, “d”]. Whitespaces are ignored. We will use and extend `org.apache.flink.util.TimeUtils` for this purposes.

#### Requirement Summary
This section specifies adding native `ConfigOption<Duration>` support with a user-friendly string format (e.g., "20ms") alongside the standard `java.time.Duration` format, using `TimeUtils` for parsing. The PR implements Duration type support via `durationType()` in the `ConfigOptions` builder and Duration conversion logic in `Configuration.java` that delegates to `TimeUtils`.

**File proportion:** 2/13 files mapped (15.4%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-core/src/main/java/org/apache/flink/configuration/ConfigOptions.java` | Modified | +203 / -2 | — | `OptionBuilder.durationType` |
| `flink-core/src/main/java/org/apache/flink/configuration/Configuration.java` | Modified | +262 / -175 | — | `Configuration.convertToDuration` |

#### Modification Summary
- **`flink-core/src/main/java/org/apache/flink/configuration/ConfigOptions.java`**: Adds the `durationType()` factory method on `OptionBuilder` that returns a `TypedConfigOptionBuilder<Duration>` as specified.
- **`flink-core/src/main/java/org/apache/flink/configuration/Configuration.java`**: `convertToDuration` parses the human-readable duration string (e.g., "20ms") via `TimeUtils` and feeds the typed `get`/`getOptional` path, as specified.

---

## Section 14: Memory Size Options
*Path: Proposed Changes > Memory Size Options*
*Classification: Implementable*

> We should add native support for ConfigOption<MemorySize>:
>
> `ConfigOption<MemorySize> option = ...`
>
> `MemorySize size = conf.get(option)`
>
> For the string representation we would reuse the parsing logic from new MemorySize().
>
> The format is as follows “d+ [unit]”, where unit is one of [“b”, “bytes”, “k”, “kb”, "kibibytes", "m", "mb", "mebibytes", "g", "gb", "gibibytes", "t", "tb", "tebibytes"].

#### Requirement Summary
This section specifies adding native `ConfigOption<MemorySize>` support, reusing the existing `MemorySize` parsing logic for string representation with unit suffixes (b, kb, mb, gb, tb). The PR implements MemorySize type support via `memoryType()` in the `ConfigOptions` builder and MemorySize conversion logic in `Configuration.java`.

**File proportion:** 2/13 files mapped (15.4%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-core/src/main/java/org/apache/flink/configuration/ConfigOptions.java` | Modified | +203 / -2 | — | `OptionBuilder.memoryType` |
| `flink-core/src/main/java/org/apache/flink/configuration/Configuration.java` | Modified | +262 / -175 | — | `Configuration.convertToMemorySize` |

#### Modification Summary
- **`flink-core/src/main/java/org/apache/flink/configuration/ConfigOptions.java`**: Adds the `memoryType()` factory method on `OptionBuilder` that returns a `TypedConfigOptionBuilder<MemorySize>` as specified.
- **`flink-core/src/main/java/org/apache/flink/configuration/Configuration.java`**: `convertToMemorySize` reuses `MemorySize.parse()` to translate the human-readable memory strings (e.g., "16mb") into the typed `MemorySize` values returned by `get`/`getOptional`, as specified.

---

## Section 15: Map Options
*Path: Proposed Changes > Map Options*
*Classification: Implementable*

> We suggest introducing properties ConfigOption type to support a map of custom string properties. The same escaping logic as for lists applies.
>
> ConfigOption<Map<String, String>> option = ....
>
> Map<String, String> properties = conf.get(option)
>
> We suggest to use the following string format:
>
> exec.global-job-parameters = key1:value1, key2:value2, key3:value3
>
> We use comma for separation of entries as it is weaker than the semicolon for lists. It is possible to have a list of maps.

#### Requirement Summary
This section specifies adding `ConfigOption<Map<String, String>>` support with comma-separated `key:value` string format and the same escaping logic as lists. The PR implements Map type support via `mapType()` in the `ConfigOptions` builder and Map conversion logic in `Configuration.java`.

**File proportion:** 3/13 files mapped (23.1%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-core/src/main/java/org/apache/flink/configuration/ConfigOptions.java` | Modified | +203 / -2 | — | `OptionBuilder.mapType` |
| `flink-core/src/main/java/org/apache/flink/configuration/Configuration.java` | Modified | +262 / -175 | — | `Configuration.convertToProperties` |
| `flink-core/src/main/java/org/apache/flink/configuration/StructuredOptionsSplitter.java` | Added | +176 / -0 | — | `StructuredOptionsSplitter.splitEscaped` |

#### Modification Summary
- **`flink-core/src/main/java/org/apache/flink/configuration/ConfigOptions.java`**: Adds the `mapType()` factory method on `OptionBuilder` that returns a `TypedConfigOptionBuilder<Map<String, String>>` as specified.
- **`flink-core/src/main/java/org/apache/flink/configuration/Configuration.java`**: `convertToProperties` parses the comma-separated `key:value` pairs into a `Map<String, String>` for the typed `get`/`getOptional` path, as specified by Section 15.
- **`flink-core/src/main/java/org/apache/flink/configuration/StructuredOptionsSplitter.java`**: `splitEscaped` is reused by the map parser to honor the same quoting/escaping rules as lists — Section 15 explicitly states map entries follow the list escaping logic.

---

## Section 19: Test Plan
*Classification: Implementable*

> The implementation can be tested with unit tests for every new feature section listed in Proposed Changes.

#### Requirement Summary
This section specifies that the implementation should be tested with unit tests for each feature section (typed ConfigOption, lists, Duration, MemorySize, Map). The PR adds comprehensive test classes covering type conversions, invalid format parsing, ReadableConfig/WritableConfig contract validation, and list splitting.

**File proportion:** 6/13 files mapped (46.2%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `flink-core/src/test/java/org/apache/flink/configuration/ConfigurationConversionsTest.java` | Added | +378 / -0 | — | — |
| `flink-core/src/test/java/org/apache/flink/configuration/ConfigurationParsingInvalidFormatsTest.java` | Added | +87 / -0 | — | — |
| `flink-core/src/test/java/org/apache/flink/configuration/ConfigurationTest.java` | Modified | +0 / -126 | — | — |
| `flink-core/src/test/java/org/apache/flink/configuration/ReadableWritableConfigurationTest.java` | Added | +265 / -0 | — | — |
| `flink-core/src/test/java/org/apache/flink/configuration/StructuredOptionsSplitterTest.java` | Added | +158 / -0 | — | — |
| `flink-core/src/test/java/org/apache/flink/configuration/UnmodifiableConfigurationTest.java` | Modified | +2 / -1 | — | — |

#### Modification Summary
- **`flink-core/src/test/java/org/apache/flink/configuration/ConfigurationConversionsTest.java`**: Comprehensive parameterized unit tests for type conversions across all new data types (Integer, Long, Boolean, Float, Double, String, Duration, MemorySize, Map, List, Enum) as specified by "unit tests for every new feature section."
- **`flink-core/src/test/java/org/apache/flink/configuration/ConfigurationParsingInvalidFormatsTest.java`**: Parameterized negative test cases validating error handling for invalid format strings across Duration, MemorySize, and other new types.
- **`flink-core/src/test/java/org/apache/flink/configuration/ConfigurationTest.java`**: Removes old conversion tests that are superseded by the new `ConfigurationConversionsTest`, consolidating test coverage for the new typed configuration system.
- **`flink-core/src/test/java/org/apache/flink/configuration/ReadableWritableConfigurationTest.java`**: Tests for the new `ReadableConfig`/`WritableConfig` interface methods (`get`, `getOptional`, `set`) on `Configuration`, covering the proposed changes to Configuration section.
- **`flink-core/src/test/java/org/apache/flink/configuration/StructuredOptionsSplitterTest.java`**: Tests for the `StructuredOptionsSplitter` quoting and escaping logic, covering the List Options section's semicolon splitting and quote escaping specification.
- **`flink-core/src/test/java/org/apache/flink/configuration/UnmodifiableConfigurationTest.java`**: Adjusts the mutation detection test to account for the new `WritableConfig#set` method, which is tested separately in `ReadableWritableConfigurationTest`.

---

## Unmapped Requirement Sections

None

## Unmapped PR Files

None
