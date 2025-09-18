library(ellmer)
library(brickster)
library(mcptools)
library(purrr)
library(jsonlite)

# Define a tool for LLM to discover available SQL warehouses
db_warehouse_discovery <- ellmer::tool(
  fun = function() {
    warehouses <- brickster::db_sql_warehouse_list() # list all accessible warehouses
    purrr::map(
      warehouses,
      ~ .x[c("id", "name", "size", "creator_name", "state")]
    ) |>
      jsonlite::toJSON(auto_unbox = TRUE)
  },
  name = "list_databricks_warehouses",
  description = "Discover and list all available Databricks SQL warehouses in the workspace. This tool returns information about warehouse IDs, names, states, cluster sizes, and other metadata needed to select an appropriate warehouse for running SQL queries.",
  arguments = list(),
  annotations = ellmer::tool_annotations(
    title = "Databricks Warehouse Discovery Tool",
    read_only_hint = TRUE,
    open_world_hint = FALSE
  )
)
# Define a tool for LLM to list Unity Catalog catalogs
db_uc_catalogs <- ellmer::tool(
  fun = function(max_results = 50, include_browse = TRUE) {
    catalogs <- brickster::db_uc_catalogs_list(
      max_results = max_results,
      include_browse = include_browse
    )
    purrr::map(
      catalogs,
      ~ .x[c("name", "owner", "created_by", "catalog_type")]
    )
  },
  name = "list_catalogs",
  description = "List all Databricks catalogs available in the Databricks workspace. Returns catalog names, metadata, ownership information, and access permissions. Use this to discover the top-level data organization structure in Unity Catalog.",
  arguments = list(
    max_results = ellmer::type_integer(
      "Maximum number of catalogs to return. Default is 50."
    ),
    include_browse = ellmer::type_boolean(
      "Whether to include catalogs for which the principal can only access selective metadata. Default is TRUE."
    )
  ),
  annotations = ellmer::tool_annotations(
    title = "Unity Catalog Catalogs Explorer",
    read_only_hint = TRUE,
    open_world_hint = FALSE
  )
)

# Define a tool for LLM to list Unity Catalog schemas
db_uc_schemas <- ellmer::tool(
  fun = function(catalog, max_results = 50) {
    schemas <- brickster::db_uc_schemas_list(
      catalog = catalog,
      max_results = max_results
    )
    purrr::map(
      schemas,
      ~ .x[c("full_name", "name", "owner", "created_by")]
    ) |>
      jsonlite::toJSON(auto_unbox = TRUE)
  },
  name = "list_schemas",
  description = "List all schemas within a specific Databricks catalog. Returns schema names, metadata, ownership information, and access permissions. Use this after discovering catalogs to explore the schema-level organization within a catalog.",
  arguments = list(
    catalog = ellmer::type_string(
      "The name of the parent catalog to list schemas from."
    ),
    max_results = ellmer::type_integer(
      "Maximum number of schemas to return. Default is 50."
    )
  ),
  annotations = ellmer::tool_annotations(
    title = "Unity Catalog Schemas Explorer",
    read_only_hint = TRUE,
    open_world_hint = FALSE
  )
)

# Define a tool for LLM to list Unity Catalog tables and their contents
db_uc_tables <- ellmer::tool(
  fun = function(
    catalog,
    schema,
    max_results = 50,
    omit_columns = FALSE,
    include_delta_metadata = FALSE
  ) {
    tables <- brickster::db_uc_tables_list(
      catalog = catalog,
      schema = schema,
      max_results = max_results,
      omit_columns = omit_columns,
      include_delta_metadata = include_delta_metadata
    )
    purrr::map(tables, function(table) {
      metadata <- table[c(
        "full_name",
        "securable_type",
        "securable_kind",
        "owner",
        "created_by",
        "updated_at",
        "created_at"
      )]
      if (!omit_columns && !is.null(table$columns)) {
        metadata$columns <- purrr::map(
          table$columns,
          ~ .x[c("name", "type_text")]
        )
      }
      metadata
    }) |>
      jsonlite::toJSON(auto_unbox = TRUE)
  },
  name = "list_tables",
  description = "List all tables, views, and other objects within a specific Databricks schema. Returns table names, types, column information (if requested), metadata, and ownership details. Use this after discovering catalogs and schemas to explore the actual data assets.",
  arguments = list(
    catalog = ellmer::type_string(
      "The name of the parent catalog containing the schema."
    ),
    schema = ellmer::type_string("The name of the schema to list tables from."),
    max_results = ellmer::type_integer(
      "Maximum number of tables to return. Default is 50, maximum allowed is 50."
    ),
    omit_columns = ellmer::type_boolean(
      "Whether to omit column information from the response. Default is FALSE to include column details."
    ),
    include_delta_metadata = ellmer::type_boolean(
      "Whether to include Delta Lake metadata in the response. Default is FALSE."
    )
  ),
  annotations = ellmer::tool_annotations(
    title = "Unity Catalog Tables Explorer",
    read_only_hint = TRUE,
    open_world_hint = FALSE
  )
)

mcptools::mcp_server(
  tools = list(
    db_uc_catalogs,
    db_uc_schemas,
    db_uc_tables,
    db_warehouse_discovery
  )
)
