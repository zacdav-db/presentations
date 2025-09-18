db_warehouse_discovery <- ellmer::tool(
  fun = function() {
    warehouses <- brickster::db_sql_warehouse_list()
    purrr::map(
      warehouses,
      ~ .x[c("id", "name", "size", "creator_name", "state")]
    )
  },
  name = "list_databricks_warehouses",
  description = "Returns metadata for available warehouses: IDs, names, state, size, etc.",
  arguments = list(),
  annotations = ellmer::tool_annotations(
    title = "Databricks Warehouse Discovery Tool",
    read_only_hint = TRUE,
    open_world_hint = FALSE
  )
)

mcptools::mcp_server(tools = list(db_warehouse_discovery))
