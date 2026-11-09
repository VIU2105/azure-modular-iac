
resource "azurerm_app_service_environment_v3" "app_service_environment_v3" {
  for_each            = var.app_service_environment_v3
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  subnet_id           = each.value.subnet_id

  # Optionals
  allow_new_private_endpoint_connections = each.value.allow_new_private_endpoint_connections
  internal_load_balancing_mode           = each.value.internal_load_balancing_mode
  remote_debugging_enabled               = each.value.remote_debugging_enabled

  # Mutually exclusive knobs (we enforce with a precondition below)
  dedicated_host_count = each.value.dedicated_host_count
  zone_redundant       = each.value.zone_redundant
  # dedicated_host_count = each.value.zone_redundant ? null : each.value.dedicated_host_count


  # Optional cluster settings
  dynamic "cluster_setting" {
    for_each = lookup(each.value, "cluster_settings", [])
    content {
      name  = cluster_setting.value.name
      value = cluster_setting.value.value
    }
  }

  tags = each.value.tags

  lifecycle {
    precondition {
      condition     = alltrue([for v in values(each.value.tags) : trimspace(v) != ""])
      error_message = "RG '${each.key}' creation blocked: one or more required tags are empty."
    }
  }


}

output "service_app_env_ids" {
  description = "Map of service plan IDs created in this ASE"
  value = { for _, fa in azurerm_app_service_environment_v3.app_service_environment_v3 : fa.name => fa.id }
 
 # key is ignore by _ and manually fetching it's value here fa.name is function name which is fa.<attribute>
  
}


