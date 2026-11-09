# Existing Code
# resource "azurerm_service_plan" "ASECACDMZSP34" {
#   name                       = "ASE-CAC-DMZ-SP34"
#   location                   = var.location
#   resource_group_name        = module.resource_groups["ASE-CAC-DMZ"].name
#   app_service_environment_id = "/subscriptions/1288c093-3ec0-4f4f-b755-f43d7795b217/resourceGroups/ASE-CAC-DMZ/providers/Microsoft.Web/hostingEnvironments/ASE02-CAC-DMZ"
#   os_type                    = "Windows"
#   sku_name                   = "I1v2"
#   worker_count               = 2

#   tags = {
#     "ApplicationName" = "Admin Tools"
#     "BusinessService" = "Engineering"
#     "Portfolio"       = "Delivery Practices"
#     "PortfolioArea"   = "PDG Engineering Delivery"
#     "Environment"     = "PRD"
#     "OpsTeam"         = "DPD"
#     "RequestedBy"     = "joe.walker@hatch.com"
#     "Vendor"          = "Microsoft"
#   }
# }

# One resource that can create N storage accounts using for_each over the map input.

resource "azurerm_storage_account" "storage_account" {
  for_each = var.storage_accounts

  # ---------------- Core ----------------
  name                     = each.value.name #
  resource_group_name      = each.value.resource_group_name #
  location                 = each.value.location #
  account_tier             = each.value.account_tier #
  account_replication_type = each.value.account_replication_type #
  min_tls_version                     = each.value.min_tls_version #
  access_tier                         = each.value.access_tier #
  account_kind                        = each.value.account_kind #
  queue_encryption_key_type           = each.value.queue_encryption_key_type #
  table_encryption_key_type           = each.value.table_encryption_key_type #
  allow_nested_items_to_be_public     = each.value.allow_nested_items_to_be_public #
  public_network_access_enabled       = each.value.public_network_access_enabled #
  
  tags = each.value.tags #

  # --------------- General --------------
  
  provisioned_billing_model_version   = each.value.provisioned_billing_model_version
  cross_tenant_replication_enabled    = each.value.cross_tenant_replication_enabled
  edge_zone                           = each.value.edge_zone
  https_traffic_only_enabled          = each.value.https_traffic_only_enabled
  shared_access_key_enabled           = each.value.shared_access_key_enabled
  default_to_oauth_authentication     = each.value.default_to_oauth_authentication
  is_hns_enabled                      = each.value.is_hns_enabled
  nfsv3_enabled                       = each.value.nfsv3_enabled
  large_file_share_enabled            = each.value.large_file_share_enabled
  local_user_enabled                  = each.value.local_user_enabled
  infrastructure_encryption_enabled   = each.value.infrastructure_encryption_enabled
  allowed_copy_scope                  = each.value.allowed_copy_scope
  sftp_enabled                        = each.value.sftp_enabled
  dns_endpoint_type                   = each.value.dns_endpoint_type

  lifecycle {
    # precondition {
    #   condition     = alltrue([for v in values(each.value.tags) : trimspace(v) != ""])
    #   error_message = "RG '${each.key}' creation blocked: one or more required tags are empty."
    # }
    # We have add one more tag "SolutionName" which is used by the StartStopV2 solution, we make it optional in variable definition to avoid forcing all storage accounts to have it.
  #  precondition {
  #   condition = alltrue([
  #     trimspace(each.value.tags.owner)           != "",
  #     trimspace(each.value.tags.ApplicationName) != "",
  #     trimspace(each.value.tags.CreatedBy)       != "",
  #     trimspace(each.value.tags.BusinessService) != "",
  #     trimspace(each.value.tags.Environment)     != "",
  #     trimspace(each.value.tags.OpsTeam)         != "",
  #     trimspace(each.value.tags.Portfolio)       != "",
  #     trimspace(each.value.tags.PortfolioArea)   != "",
  #     trimspace(each.value.tags.RequestedBy)     != "",
  #     trimspace(each.value.tags.Vendor)          != ""
  #    ])
  #    error_message = "RG '${each.key}' creation blocked: one or more required tags are empty."
  #   }

    ignore_changes = [
      tags["SolutionName: StartStopV2"],
      tags["hidden-related:diagnostics/changeAnalysisScanEnabled"]
    ]
  }
}