
# One resource that can create N service plan and Isolated SKUs used with APp service Environments.
# We are having 3 App Service Environments Aus-E, Can-C , SA-North 

# If the ASE is created by another team/subscription, you might use a data source.
# data "azurerm_app_service_environment_v3" "app_service_environment_v3" {
#   # To get the App Service Environment ID
#   for_each = var.service_plans
#   name                = each.value.existing_ase_name
#   resource_group_name = each.value.existing_ase_rg
# }

resource "azurerm_service_plan" "service_plan" {
  for_each = var.service_plans

  # Required
  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  os_type             = each.value.os_type
  sku_name            = each.value.sku_name

  # Optional
  app_service_environment_id      = var.service_env_app_ids[each.value.existing_ase_name]
  # app_service_environment_id      = data.azurerm_app_service_environment_v3.app_service_environment_v3[each.key].id
  premium_plan_auto_scale_enabled = each.value.premium_plan_auto_scale_enabled
  maximum_elastic_worker_count    = each.value.maximum_elastic_worker_count
  worker_count                    = each.value.worker_count
  per_site_scaling_enabled        = each.value.per_site_scaling_enabled
  zone_balancing_enabled          = each.value.zone_balancing_enabled
  tags                            = each.value.tags

  # NOTE:
  # If your ASE ID comes from a resource in another module/run and Terraform cannot infer
  # the dependency graph, consider adding an explicit depends_on here referencing that module.
  # Example (uncomment and adjust):
  # depends_on = [module.networking, module.ase]

  lifecycle {
    precondition {
      # condition     = alltrue([for v in values(each.value.tags) : try(trimspace(v), "") != ""])
      condition = alltrue([
      trimspace(each.value.tags.ApplicationName) != "",
      trimspace(each.value.tags.Environment) != "",
      trimspace(each.value.tags.OpsTeam) != "",
      trimspace(each.value.tags.Portfolio) != "",
      trimspace(each.value.tags.PortfolioArea) != "",
      trimspace(each.value.tags.RequestedBy) != "",
      trimspace(each.value.tags.Vendor) != ""
    ])
      error_message = "RG '${each.key}' failed: missing required tags (ApplicationName, Environment, OpsTeam, Portfolio, PortfolioArea, RequestedBy, Vendor)."
    }
    ignore_changes = [ 
      tags["hidden-related:diagnostics/changeAnalysisScanEnabled"]
     ]
  }
}

output "service_app_ids" {
  description = "Map of service plan IDs created in this ASE"
  value = { for _, fa in azurerm_service_plan.service_plan : fa.name => fa.id }
 
 # key is ignore by _ and manually fetching it's value here fa.name is function name which is fa.<attribute>
  
}
