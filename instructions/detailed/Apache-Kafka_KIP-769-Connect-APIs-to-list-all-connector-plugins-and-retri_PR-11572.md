> Implement the requirement described below in the project's source tree.
> Put implementation changes in `solution.patch`. If you add tests, put
> them in `test.patch`; tests are optional and must not be included in
> `solution.patch`.
>
> This environment has no outbound internet access — `curl`/`wget`, `git fetch`/`clone`, package installs, and web fetch/search will all fail. Implement the requirements using only the code already in the workspace and your own knowledge; do not attempt to fetch or search external resources.

---

# KIP-769: Connect APIs to list all connector plugins and retrieve their configuration definitions

# Motivation

When starting a connector, users must provide the connector configuration. The configuration often also includes configurations for other plugins such as SMTs or converters. Today, Connect does not provide a way to see what plugins are installed apart from connectors. This make it difficult for users building data pipeline to know which plugins are available and what is possible. Basically they have to know how the Connect runtime is set up. Even once they know the plugins that are available, they then have to go look at the plugins documentation or, in the worst case, look directly at the source code to find their configuration definitions.   
  
Connector plugins should be discoverable via the REST API. Their configuration definitions should also be easily retrieved. This would significantly ease the process of building pipelines and enable building tools and UIs that can manage Connect data pipelines.

# Public Interfaces

  * `GET /connector-plugins`: This endpoint will be updated to allow listing all plugins. The response structure of the objects in the array remain unchanged; on the implementation side each such object is a `PluginInfo` entity carrying the plugin's `class`, `type`, and `version`, generalizing the former connector-only plugin entity so that every plugin type (transformations, converters, header converters, and predicates) can be represented. A new query parameter "`connectorsOnly`" will be added and it will default to true so it's fully compatible with the current behavior. Users will be able to list all Connectors, Transformations, Converters, HeaderConverters and Predicates plugins by setting it to false. Classes that implement multiple plugin types will appear once for each type. For example SimpleHeaderConverter will be listed as a converter and as a header_converter. Possible values for the "type" field are "sink", "source", "converter", "header_converter", "transformation" and "predicate".

For example GET `/connector-plugins?connectorsOnly=false` will return:

```json
[
  {
    "class": "org.apache.kafka.connect.file.FileStreamSinkConnector",
    "type": "sink",
    "version": "3.2.0"
  },
  {
    "class": "org.apache.kafka.connect.file.FileStreamSourceConnector",
    "type": "source",
    "version": "3.2.0"
  },   {
    "class": "org.apache.kafka.connect.converters.ByteArrayConverter",
    "type": "converter"
  },
  {
    "class": "org.apache.kafka.connect.transforms.Cast$Value",
    "type": "transformation"
  },
  {
    "class": "org.apache.kafka.connect.transforms.predicates.HasHeaderKey",
    "type": "predicate"
  },
  {
    "class": "org.apache.kafka.connect.storage.SimpleHeaderConverter",
    "type": "header_converter"
  },
  {
    "class": "org.apache.kafka.connect.storage.SimpleHeaderConverter",
    "type": "converter"
  },   
  ...
]
```

Currently only Connector plugins are versioned, so we won't include the version field for other plugins.

  * `GET /connector-plugins/<plugin>/config`: This new endpoint will return the configuration definitions of the specified plugin. It will work with all plugins returned by `/connector_plugins`.

The plugin can be specified via its fully qualified class name or its Connect alias like in the existing `/connector-plugins/<plugin>/config/validate` endpoint. If a plugin does not override the `config()` method, the response is an empty array.

For example, accessing http://localhost:8083/connector-plugins/org.apache.kafka.connect.transforms.Cast$Value/config will return:

```json
[
  {
    "name": "spec",
    "type": "LIST",
    "required": true,
    "default_value": null,
    "importance": "HIGH",
    "documentation": "List of fields and the type to cast them to of the form field1:type,field2:type to cast fields of Maps or Structs. A single type to cast the entire value. Valid types are int8, int16, int32, int64, float32, float64, boolean, and string. Note that binary fields can only be cast to string.",
    "group": null,
    "width": "NONE",
    "display_name": "spec",
    "dependents": [],
    "order": -1
  }
]
```


### Implementation Guidance

1. In `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/rest/resources/ConnectorPluginsResource.java`, update `ConnectorPluginsResource.ConnectorPluginsResource`, `ConnectorPluginsResource.addConnectorPlugins`, and `ConnectorPluginsResource.getConnectorPlugins`. The constructor (`ConnectorPluginsResource`) now eagerly populates all plugin types (sink connectors, source connectors, transformations, predicates, converters, header converters) via the new `addConnectorPlugins` helper, and `getConnectorPlugins` exposes the populated list to internal callers. Typed exclude lists (`SINK_CONNECTOR_EXCLUDES`, `SOURCE_CONNECTOR_EXCLUDES`, `TRANSFORM_EXCLUDES`) replace the single `CONNECTOR_EXCLUDES`.

2. In `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/rest/entities/PluginInfo.java`, update `NoVersionFilter.equals`, `NoVersionFilter.hashCode`, `PluginInfo.PluginInfo`, `PluginInfo.equals`, `PluginInfo.toString`, `PluginInfo.type`, and `PluginInfo.version`. Renamed from `ConnectorPluginInfo.java`. Changes the `type` field from `ConnectorType` to `PluginType` to support all plugin types. The `type` method now returns `String` (via `PluginType.toString`). Adds a `NoVersionFilter` inner class used as a `@JsonInclude` custom filter to omit the `version` field when it equals `"undefined"`, implementing the requirement that non-connector plugins do not include the version field. The constructor now accepts `PluginDesc<?>` instead of `PluginDesc<Connector>`.

3. In `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/isolation/DelegatingClassLoader.java`, update `DelegatingClassLoader.DelegatingClassLoader`, `DelegatingClassLoader.addAllAliases`, `DelegatingClassLoader.connectors`, `DelegatingClassLoader.getResources`, `DelegatingClassLoader.initPluginLoader`, `DelegatingClassLoader.registerPlugin`, `DelegatingClassLoader.scanPluginPath`, `DelegatingClassLoader.scanUrlsAndAddPlugins`, `DelegatingClassLoader.sinkConnectors`, `DelegatingClassLoader.sourceConnectors`, and `DelegatingClassLoader.versionFor`. Splits the single `connectors` set into separate `sinkConnectors` and `sourceConnectors` sets, enabling type-safe access to each connector subtype. Adds `sinkConnectors` and `sourceConnectors` accessors. The `connectors` method is preserved for backward compatibility as a union of both sets. Makes `UNDEFINED_VERSION` public so `PluginInfo.NoVersionFilter` can reference it. Updates `scanUrlsAndAddPlugins` to register sink and source connectors separately.

4. In `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/isolation/PluginType.java`, update `PluginType`. Adds `HEADER_CONVERTER` and `PREDICATE` enum values, removes the generic `CONNECTOR` value. This enables the REST API to distinguish all six plugin types as specified: sink, source, converter, header_converter, transformation, predicate.

5. In `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/isolation/Plugins.java`, update `Plugins.connectorClass`, `Plugins.connectors`, `Plugins.headerConverters`, `Plugins.sinkConnectors`, and `Plugins.sourceConnectors`. extends Connector>` for the split connector sets.
# Proposed Changes

**REST API:**

  * A new path will be added to `ConnectorPluginsResource` to retrieve the plugin configuration definitions

```java
@GET
@Path("/{plugin}/config")
public List<ConfigKeyInfo> getPluginConfig() {}
```

  * Listing connector plugin will accept an optional query parameter "`connectorsOnly`" that defaults to `true`

```java
@GET
@Path("/")
public List<ConnectorPluginInfo> listConnectorPlugins(@DefaultValue("true") @QueryParam("connectorsOnly") boolean connectorsOnly) {}
```

**Converter interface:**

Add a `config() `method to `Converter` with a default implementation.

```java
public interface Converter {

[...]

    /**
     * Configuration specification for this set of converters.
     * @return the configuration specification; may not be null
     */
    default ConfigDef config() {
        return new ConfigDef();
    }
}
```

It's common for custom converters to implement both `Converter` and `HeaderConverter`. As the 2 methods to retrieve the `ConfigDef` will have exactly the same signature, it will still be possible to implement both interfaces.


### Implementation Guidance

1. In `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/rest/resources/ConnectorPluginsResource.java`, update `ConnectorPluginsResource.getConnectorConfigDef` and `ConnectorPluginsResource.listConnectorPlugins`. `getConnectorConfigDef` implements the new `GET /{plugin}/config` endpoint described by the section's first code block — it delegates to `herder.connectorPluginConfig` to retrieve configuration definitions for any plugin type. `listConnectorPlugins` implements the second code block — it accepts the `@DefaultValue("true") @QueryParam("connectorsOnly")` parameter and filters the plugin list accordingly (sink/source connectors only when `true`, all plugin types when `false`).

2. In `connect/api/src/main/java/org/apache/kafka/connect/storage/Converter.java`, update `Converter.config`. Adds the `config` default method returning an empty `ConfigDef`, as specified in the "Converter interface" subsection. This enables the config endpoint to retrieve converter configuration definitions, with a no-op default for converters that do not override it.

3. In `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/Herder.java`, update `Herder.connectorPluginConfig`. Adds the `connectorPluginConfig(String pluginName)` method to the `Herder` interface, returning `List<ConfigKeyInfo>`, providing the contract for retrieving plugin configuration definitions.

4. In `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/AbstractHerder.java`, update `AbstractHerder.connectorPluginConfig` and `AbstractHerder.convertConfigKey`. Implements `connectorPluginConfig` with a `PluginType`-based switch that instantiates the plugin via `plugins.newPlugin`, determines its type, and calls the appropriate `config` method (`Connector.config`, `Converter.config`, `HeaderConverter.config`, `Transformation.config`, or `Predicate.config`). Makes `convertConfigKey` public so the REST resource layer can use it. Throws `NotFoundException` for unknown plugins and `BadRequestException` for invalid plugin types.

5. In `connect/runtime/src/main/java/org/apache/kafka/connect/runtime/isolation/Plugins.java`, update `Plugins.newPlugin`. Adds `newPlugin(String classOrAlias)` method that instantiates any plugin by class name or alias, supporting the `AbstractHerder.connectorPluginConfig` implementation which needs to instantiate arbitrary plugin types to call their `config` methods.
# Compatibility, Deprecation, and Migration Plan

  * `/connector-plugins` keeps its current behavior and will only expose the new behavior when a new query parameter is set.
  * When accessing `/connector-plugins/<plugin>/config` on existing converters that don't implement the `config()` method, an empty array will be returned. If a converter is also implementing `HeaderConverter`, and hence already have a `config()` method, it will be automatically used and the config will be returned.
  * `/connector-plugins/<plugin>/config` is a new endpoint that doesn't cause compatibility issues.

I propose to flip the query parameter value to list all plugins by default in the next major release.

# Rejected Alternatives

  * Add a new endpoint /plugins for listing all plugins: It would be confusing to list both worker and connector plugins together. We'd then end up with 3 endpoints, /plugins, /worker-plugins and /connector-plugins which is as confusing!
  * Group connectors by type when listing them: This would break compatibility with the existing /connector-plugins behavior. As it's a very commonly used endpoint, it's preferred to keep compatibility.
  * Add a new endpoint /worker-plugins to list worker plugins (Rest Extensions and Config Providers): The use case is to allow administrators to check the plugins installed in each worker. Connect shouldn't expose worker internal details to all users and it's not clear what information would be useful for admins. Also Connect already has a /admin endpoint which should be reused for admin tasks.
  * Make all plugins implement Versioned. Initially we wanted to make all plugins consistent, but this either force having a default implementation for version() which would allow Connectors to not implement it, or force introducing another interface (PossiblyVersioned) to version other plugins which did not make a lot of sense since version does not have any contract today.
