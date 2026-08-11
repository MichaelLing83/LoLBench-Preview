# Apache Kafka - KIP-769: Connect APIs to list all connector plugins and retrieve their configuration definitions

**PR:** https://github.com/apache/kafka/pull/11572
**Requirement Doc:** https://cwiki.apache.org/confluence/display/KAFKA/KIP-769

## Matching Statistics
- **Requirement Doc Coverage:** 2/2 implementable sections mapped (100.0%)
  - 0 unmapped
- **PR File Coverage:** 8/27 files mapped (29.6%) + 19/27 files associated (70.4%) = 27/27 accounted (100.0%)
  - 0 unmapped

### Section Classification Summary
| # | Section | Implementable | Mapped? | Category |
|---|---------|---------------|--------|----------|
| 1 | KIP-769: Connect APIs to list all connector plugins and retrieve their configuration definitions | No | N/A | knowledge |
| 2 | Status | No | N/A | process |
| 3 | Motivation | No | N/A | contextual |
| 4 | Public Interfaces | Yes | Yes | implementation |
| 5 | Proposed Changes | Yes | Yes | implementation |
| 6 | Compatibility, Deprecation, and Migration Plan | No | N/A | contextual |
| 7 | Rejected Alternatives | No | N/A | contextual |

### PR File Summary
| # | File | Category | Mapped To | Associated To |
|---|------|----------|-----------|---------------|
| 1 | `connect/api/src/main/java/org/apache/kafka/connect/storage/Converter.java` | source | Section 5 | — |
| 2 | `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/AbstractHerder.java` | source | Section 5 | — |
| 3 | `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/Herder.java` | source | Section 5 | — |
| 4 | `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/PredicatedTransformation.java` | source | — | Section 4 |
| 5 | `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/isolation/DelegatingClassLoader.java` | source | Section 4 | — |
| 6 | `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/isolation/PluginScanResult.java` | source | — | Section 4 |
| 7 | `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/isolation/PluginType.java` | source | Section 4 | — |
| 8 | `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/isolation/PluginUtils.java` | source | — | Section 4 |
| 9 | `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/isolation/Plugins.java` | source | Section 4, Section 5 | — |
| 10 | `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/rest/entities/PluginInfo.java` | source | Section 4 | — |
| 11 | `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/rest/resources/ConnectorPluginsResource.java` | source | Section 4, Section 5 | — |
| 12 | `connect/runtime/src/main/java/org/apache/kafka/connect/tools/VerifiableSinkConnector.java` | source | — | Section 4 |
| 13 | `connect/runtime/src/test/java/org/apache/kafka/connect/integration/MonitorableSinkConnector.java` | test | — | Section 4 |
| 14 | `connect/runtime/src/test/java/org/apache/kafka/connect/integration/MonitorableSourceConnector.java` | test | — | Section 4 |
| 15 | `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/AbstractHerderTest.java` | test | — | Section 5 |
| 16 | `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/PredicatedTransformationTest.java` | test | — | Section 4 |
| 17 | `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/SampleConverterWithHeaders.java` | test | — | Section 4 |
| 18 | `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/SampleHeaderConverter.java` | test | — | Section 4 |
| 19 | `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/SamplePredicate.java` | test | — | Section 4 |
| 20 | `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/SampleSinkConnector.java` | test | — | Section 4 |
| 21 | `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/SampleSourceConnector.java` | test | — | Section 4 |
| 22 | `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/SampleTransformation.java` | test | — | Section 4 |
| 23 | `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/WorkerSinkTaskTest.java` | test | — | Section 4 |
| 24 | `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/WorkerSourceTaskTest.java` | test | — | Section 4 |
| 25 | `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/rest/entities/PluginInfoTest.java` | test | — | Section 4 |
| 26 | `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/rest/resources/ConnectorPluginsResourceTest.java` | test | — | Section 4 |
| 27 | `gradle/spotbugs-exclude.xml` | build | — | Section 4 |

---

## Section 4: Public Interfaces
*Path: Public Interfaces*
*Classification: Implementable*

>   * `GET /connector-plugins`: This endpoint will be updated to allow listing all plugins. The response structure of the objects in the array remain unchanged. A new query parameter "`connectorsOnly`" will be added and it will default to true so it's fully compatible with the current behavior. Users will be able to list all Connectors, Transformations, Converters, HeaderConverters and Predicates plugins by setting it to false. Classes that implement multiple plugin types will appear once for each type. For example SimpleHeaderConverter will be listed as a converter and as a header_converter. Possible values for the "type" field are "sink", "source", "converter", "header_converter", "transformation" and "predicate".
>
> For example GET `/connector-plugins?connectorsOnly=false` will return:
>
> ```json
> [
>   {
>     "class": "org.apache.kafka.connect.file.FileStreamSinkConnector",
>     "type": "sink",
>     "version": "3.2.0"
>   },
>   {
>     "class": "org.apache.kafka.connect.file.FileStreamSourceConnector",
>     "type": "source",
>     "version": "3.2.0"
>   },   {
>     "class": "org.apache.kafka.connect.converters.ByteArrayConverter",
>     "type": "converter"
>   },
>   {
>     "class": "org.apache.kafka.connect.transforms.Cast$Value",
>     "type": "transformation"
>   },
>   {
>     "class": "org.apache.kafka.connect.transforms.predicates.HasHeaderKey",
>     "type": "predicate"
>   },
>   {
>     "class": "org.apache.kafka.connect.storage.SimpleHeaderConverter",
>     "type": "header_converter"
>   },
>   {
>     "class": "org.apache.kafka.connect.storage.SimpleHeaderConverter",
>     "type": "converter"
>   },   
>   ...
> ]
> ```
>
> Currently only Connector plugins are versioned, so we won't include the version field for other plugins.
>
>   * `GET /connector-plugins/<plugin>/config`: This new endpoint will return the configuration definitions of the specified plugin. It will work with all plugins returned by `/connector_plugins`.
>
> The plugin can be specified via its fully qualified class name or its Connect alias like in the existing `/connector-plugins/<plugin>/config/validate` endpoint. If a plugin does not override the `config()` method, the response is an empty array.
>
> For example, accessing http://localhost:8083/connector-plugins/org.apache.kafka.connect.transforms.Cast$Value/config will return:
>
> ```json
> [
>   {
>     "name": "spec",
>     "type": "LIST",
>     "required": true,
>     "default_value": null,
>     "importance": "HIGH",
>     "documentation": "List of fields and the type to cast them to of the form field1:type,field2:type to cast fields of Maps or Structs. A single type to cast the entire value. Valid types are int8, int16, int32, int64, float32, float64, boolean, and string. Note that binary fields can only be cast to string.",
>     "group": null,
>     "width": "NONE",
>     "display_name": "spec",
>     "dependents": [],
>     "order": -1
>   }
> ]
> ```

#### Requirement Summary
This section specifies two REST API changes: (1) updating `GET /connector-plugins` to accept a `connectorsOnly` query parameter (defaulting to `true`) so that when set to `false` it returns all plugin types (sink, source, converter, header_converter, transformation, predicate) with version omitted for non-connector plugins; and (2) adding a new `GET /connector-plugins/<plugin>/config` endpoint that returns configuration definitions for any plugin type. The PR implements these by refactoring `ConnectorPluginsResource` to populate all plugin types at construction time, adding the `connectorsOnly` query parameter to `listConnectorPlugins()`, adding the `getConnectorConfigDef()` endpoint, renaming `ConnectorPluginInfo` to `PluginInfo` with a `PluginType`-based type field and a version filter for unversioned plugins, splitting connector scanning into `sinkConnectors()`/`sourceConnectors()` in the plugin isolation layer, and adding `HEADER_CONVERTER` and `PREDICATE` to `PluginType`.

**File proportion:** 5/27 files mapped (18.5%) + 18/27 files associated (66.7%) = 23/27 accounted (85.2%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/rest/resources/ConnectorPluginsResource.java` | Modified | +56 / -19 | `ConnectorPluginsResource` | `ConnectorPluginsResource.ConnectorPluginsResource`, `ConnectorPluginsResource.addConnectorPlugins`, `ConnectorPluginsResource.getConnectorPlugins` |
| `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/rest/entities/PluginInfo.java` | Renamed | +31 / -17 | `NoVersionFilter`, `PluginInfo` | `NoVersionFilter.equals`, `NoVersionFilter.hashCode`, `PluginInfo.PluginInfo`, `PluginInfo.equals`, `PluginInfo.toString`, `PluginInfo.type`, `PluginInfo.version` |
| `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/isolation/DelegatingClassLoader.java` | Modified | +31 / -15 | `DelegatingClassLoader` | `DelegatingClassLoader.DelegatingClassLoader`, `DelegatingClassLoader.addAllAliases`, `DelegatingClassLoader.connectors`, `DelegatingClassLoader.getResources`, `DelegatingClassLoader.initPluginLoader`, `DelegatingClassLoader.registerPlugin`, `DelegatingClassLoader.scanPluginPath`, `DelegatingClassLoader.scanUrlsAndAddPlugins`, `DelegatingClassLoader.sinkConnectors`, `DelegatingClassLoader.sourceConnectors`, `DelegatingClassLoader.versionFor` |
| `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/isolation/PluginType.java` | Modified | +4 / -2 | `PluginType` | — |
| `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/isolation/Plugins.java` | Modified | +24 / -9 | `Plugins` | `Plugins.connectorClass`, `Plugins.connectors`, `Plugins.headerConverters`, `Plugins.sinkConnectors`, `Plugins.sourceConnectors` |

#### Modification Summary
- **`connect/runtime/src/main/java/org/apache/kafka/connect/runtime/rest/resources/ConnectorPluginsResource.java`**: This Section 4 row owns the supporting REST-resource scopes. The constructor (`ConnectorPluginsResource`) now eagerly populates all plugin types (sink connectors, source connectors, transformations, predicates, converters, header converters) via the new `addConnectorPlugins()` helper, and `getConnectorPlugins()` exposes the populated list to internal callers. Typed exclude lists (`SINK_CONNECTOR_EXCLUDES`, `SOURCE_CONNECTOR_EXCLUDES`, `TRANSFORM_EXCLUDES`) replace the single `CONNECTOR_EXCLUDES`. The two REST endpoints themselves — `listConnectorPlugins` (with the `connectorsOnly` query parameter) and `getConnectorConfigDef` — are attributed to Section 5 (Proposed Changes) under Check 28 single-home tuple uniqueness because that section explicitly specifies their request/response shape.
- **`connect/runtime/src/main/java/org/apache/kafka/connect/runtime/rest/entities/PluginInfo.java`**: Renamed from `ConnectorPluginInfo.java`. Changes the `type` field from `ConnectorType` to `PluginType` to support all plugin types. The `type()` method now returns `String` (via `PluginType.toString()`). Adds a `NoVersionFilter` inner class used as a `@JsonInclude` custom filter to omit the `version` field when it equals `"undefined"`, implementing the requirement that non-connector plugins do not include the version field. The constructor now accepts `PluginDesc<?>` instead of `PluginDesc<Connector>`.
- **`connect/runtime/src/main/java/org/apache/kafka/connect/runtime/isolation/DelegatingClassLoader.java`**: Splits the single `connectors` set into separate `sinkConnectors` and `sourceConnectors` sets, enabling type-safe access to each connector subtype. Adds `sinkConnectors()` and `sourceConnectors()` accessors. The `connectors()` method is preserved for backward compatibility as a union of both sets. Makes `UNDEFINED_VERSION` public so `PluginInfo.NoVersionFilter` can reference it. Updates `scanUrlsAndAddPlugins()` to register sink and source connectors separately.
- **`connect/runtime/src/main/java/org/apache/kafka/connect/runtime/isolation/PluginType.java`**: Adds `HEADER_CONVERTER` and `PREDICATE` enum values, removes the generic `CONNECTOR` value. This enables the REST API to distinguish all six plugin types as specified: sink, source, converter, header_converter, transformation, predicate.
- **`connect/runtime/src/main/java/org/apache/kafka/connect/runtime/isolation/Plugins.java`**: This Section 4 row owns the typed collection accessors that surface the split plugin sets for the listing API: `sinkConnectors()`, `sourceConnectors()`, and `headerConverters()` delegate to the new typed collections in `DelegatingClassLoader`, `connectors()` is preserved as the union for backward compatibility, and `connectorClass()` is updated to work with `PluginDesc<? extends Connector>` for the split connector sets. `Plugins.newPlugin` is attributed to Section 5 (Proposed Changes) under Check 28 single-home tuple uniqueness because that section specifies the plugin instantiation path used by `AbstractHerder.connectorPluginConfig()`.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/PredicatedTransformation.java` | Modified | +1 / -1 | Changed from package-private to `public` so `ConnectorPluginsResource.TRANSFORM_EXCLUDES` can reference it | `PredicatedTransformation` | — |
| `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/isolation/PluginScanResult.java` | Modified | +15 / -7 | Splits `connectors` field into `sinkConnectors` and `sourceConnectors` to match the `DelegatingClassLoader` refactoring | `PluginScanResult` | `PluginScanResult.PluginScanResult`, `PluginScanResult.connectors`, `PluginScanResult.sinkConnectors`, `PluginScanResult.sourceConnectors` |
| `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/isolation/PluginUtils.java` | Modified | +0 / -1 | Removes the `CONNECTOR` case from `prunedName()` switch since `PluginType.CONNECTOR` was removed | — | `PluginUtils.prunedName` |
| `connect/runtime/src/main/java/org/apache/kafka/connect/tools/VerifiableSinkConnector.java` | Modified | +2 / -2 | Fixes `VerifiableSinkConnector` to extend `SinkConnector` instead of `SourceConnector`, enabling correct classification by the split connector scanning | `VerifiableSinkConnector` | — |
| `connect/runtime/src/test/java/org/apache/kafka/connect/integration/MonitorableSinkConnector.java` | Modified | +2 / -2 | Updates `version()` method return value for compatibility with the versioning changes | — | — |
| `connect/runtime/src/test/java/org/apache/kafka/connect/integration/MonitorableSourceConnector.java` | Modified | +2 / -2 | Updates `version()` method return value for compatibility with the versioning changes | — | — |
| `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/PredicatedTransformationTest.java` | Modified | +4 / -75 | Refactors test to use new `SamplePredicate` and `SampleTransformation` test helpers instead of inline mocks; adapts to visibility change | — | — |
| `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/SampleConverterWithHeaders.java` | Renamed | +1 / -1 | Renamed from inner test class to standalone file; provides a test converter that implements both `Converter` and `HeaderConverter` for plugin scanning tests | — | — |
| `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/SampleHeaderConverter.java` | Added | +53 / -0 | New test `HeaderConverter` implementation for plugin listing tests | — | — |
| `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/SamplePredicate.java` | Added | +55 / -0 | New test `Predicate` implementation for plugin listing tests | — | — |
| `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/SampleSinkConnector.java` | Renamed | +1 / -1 | Renamed from inner test class to standalone file; provides a test sink connector for plugin listing tests | — | — |
| `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/SampleSourceConnector.java` | Renamed | +1 / -1 | Renamed from inner test class to standalone file; provides a test source connector for plugin listing tests | — | — |
| `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/SampleTransformation.java` | Added | +55 / -0 | New test `Transformation` implementation for plugin listing tests | — | — |
| `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/WorkerSinkTaskTest.java` | Modified | +1 / -1 | Updates import from `ConnectorPluginInfo` to `PluginInfo` following the rename | — | — |
| `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/WorkerSourceTaskTest.java` | Modified | +1 / -1 | Updates import from `ConnectorPluginInfo` to `PluginInfo` following the rename | — | — |
| `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/rest/entities/PluginInfoTest.java` | Added | +35 / -0 | Tests `PluginInfo` serialization/deserialization including the `NoVersionFilter` behavior | — | — |
| `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/rest/resources/ConnectorPluginsResourceTest.java` | Modified | +178 / -155 | Extensive test updates for the `connectorsOnly` query parameter and `getConnectorConfigDef()` endpoint; uses the new standalone test plugin classes | — | — |
| `gradle/spotbugs-exclude.xml` | Modified | +8 / -0 | Suppresses the `EQ_CHECK_FOR_OPERAND_NOT_COMPATIBLE_WITH_THIS` SpotBugs warning for `PluginInfo.NoVersionFilter.equals()` which intentionally compares against `String` for Jackson filtering | — | — |

---

## Section 5: Proposed Changes
*Path: Proposed Changes*
*Classification: Implementable*

> **REST API:**
>
>   * A new path will be added to `ConnectorPluginsResource` to retrieve the plugin configuration definitions
>
> ```java
> @GET
> @Path("/{plugin}/config")
> public List<ConfigKeyInfo> getPluginConfig() {}
> ```
>
>   * Listing connector plugin will accept an optional query parameter "`connectorsOnly`" that defaults to `true`
>
> ```java
> @GET
> @Path("/")
> public List<ConnectorPluginInfo> listConnectorPlugins(@DefaultValue("true") @QueryParam("connectorsOnly") boolean connectorsOnly) {}
> ```
>
> **Converter interface:**
>
> Add a `config() `method to `Converter` with a default implementation.
>
> ```java
> public interface Converter {
>
> [...]
>
>     /**
>      * Configuration specification for this set of converters.
>      * @return the configuration specification; may not be null
>      */
>     default ConfigDef config() {
>         return new ConfigDef();
>     }
> }
> ```
>
> It's common for custom converters to implement both `Converter` and `HeaderConverter`. As the 2 methods to retrieve the `ConfigDef` will have exactly the same signature, it will still be possible to implement both interfaces.

#### Requirement Summary
This section specifies three concrete implementation changes: (1) a new `@GET` path in `ConnectorPluginsResource` for retrieving plugin configuration definitions, (2) the `connectorsOnly` query parameter on the listing endpoint, and (3) adding a `config()` default method to the `Converter` interface returning an empty `ConfigDef`. The PR implements the REST resource changes in `ConnectorPluginsResource` (the `getConnectorConfigDef()` method and the `connectorsOnly` parameter on `listConnectorPlugins()`), adds the `config()` default method to `Converter`, adds `connectorPluginConfig()` to the `Herder` interface with implementation in `AbstractHerder` that uses a `PluginType`-based switch to invoke the appropriate `config()` method on each plugin type, and adds `newPlugin()` to `Plugins` for instantiating any plugin by name.

**File proportion:** 5/27 files mapped (18.5%) + 1/27 files associated (3.7%) = 6/27 accounted (22.2%)

#### Modified Files
| File | Change Type | Lines Changed | Classes | Functions |
|------|-------------|---------------|---------|-----------|
| `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/rest/resources/ConnectorPluginsResource.java` | Modified | +56 / -19 | — | `ConnectorPluginsResource.getConnectorConfigDef`, `ConnectorPluginsResource.listConnectorPlugins` |
| `connect/api/src/main/java/org/apache/kafka/connect/storage/Converter.java` | Modified | +9 / -0 | `Converter` | `Converter.config` |
| `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/Herder.java` | Modified | +9 / -0 | `Herder` | `Herder.connectorPluginConfig` |
| `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/AbstractHerder.java` | Modified | +43 / -1 | `AbstractHerder` | `AbstractHerder.connectorPluginConfig`, `AbstractHerder.convertConfigKey` |
| `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/isolation/Plugins.java` | Modified | +24 / -9 | — | `Plugins.newPlugin` |

#### Modification Summary
- **`connect/runtime/src/main/java/org/apache/kafka/connect/runtime/rest/resources/ConnectorPluginsResource.java`**: `getConnectorConfigDef()` implements the new `GET /{plugin}/config` endpoint described by the section's first code block — it delegates to `herder.connectorPluginConfig()` to retrieve configuration definitions for any plugin type. `listConnectorPlugins()` implements the second code block — it accepts the `@DefaultValue("true") @QueryParam("connectorsOnly")` parameter and filters the plugin list accordingly (sink/source connectors only when `true`, all plugin types when `false`).
- **`connect/api/src/main/java/org/apache/kafka/connect/storage/Converter.java`**: Adds the `config()` default method returning an empty `ConfigDef`, as specified in the "Converter interface" subsection. This enables the config endpoint to retrieve converter configuration definitions, with a no-op default for converters that do not override it.
- **`connect/runtime/src/main/java/org/apache/kafka/connect/runtime/Herder.java`**: Adds the `connectorPluginConfig(String pluginName)` method to the `Herder` interface, returning `List<ConfigKeyInfo>`, providing the contract for retrieving plugin configuration definitions.
- **`connect/runtime/src/main/java/org/apache/kafka/connect/runtime/AbstractHerder.java`**: Implements `connectorPluginConfig()` with a `PluginType`-based switch that instantiates the plugin via `plugins().newPlugin()`, determines its type, and calls the appropriate `config()` method (`Connector.config()`, `Converter.config()`, `HeaderConverter.config()`, `Transformation.config()`, or `Predicate.config()`). Makes `convertConfigKey()` public so the REST resource layer can use it. Throws `NotFoundException` for unknown plugins and `BadRequestException` for invalid plugin types.
- **`connect/runtime/src/main/java/org/apache/kafka/connect/runtime/isolation/Plugins.java`**: Adds `newPlugin(String classOrAlias)` method that instantiates any plugin by class name or alias, supporting the `AbstractHerder.connectorPluginConfig()` implementation which needs to instantiate arbitrary plugin types to call their `config()` methods.

#### Associated Changes
These files are not directly required by the requirement doc but must be modified to maintain repo consistency.

| File | Change Type | Lines Changed | Reason | Classes | Functions |
|------|-------------|---------------|--------|---------|-----------|
| `connect/runtime/src/test/java/org/apache/kafka/connect/runtime/AbstractHerderTest.java` | Modified | +113 / -73 | Tests for the new `connectorPluginConfig()` implementation in `AbstractHerder`, verifying config retrieval for each plugin type | — | — |

---

## Unmapped Requirement Sections

None

## Unmapped PR Files

None
