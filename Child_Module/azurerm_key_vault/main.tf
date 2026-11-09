data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyvault" {

  for_each = var.key_vaults

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  tenant_id          = data.azurerm_client_config.current.tenant_id
  #   tenant_id = each.value.tenant_id
  sku_name  = each.value.sku_name

  rbac_authorization_enabled = lookup(each.value, "rbac_authorization_enabled", false)

  public_network_access_enabled = lookup(each.value, "public_network_access_enabled", true)

  purge_protection_enabled   = lookup(each.value, "purge_protection_enabled", false)
  soft_delete_retention_days = lookup(each.value, "soft_delete_retention_days", 90)

  # Optional
  enabled_for_deployment          = lookup(each.value, "enabled_for_deployment", false)
  enabled_for_disk_encryption     = lookup(each.value, "enabled_for_disk_encryption", false)
  enabled_for_template_deployment = lookup(each.value, "enabled_for_template_deployment", false)

  # ---------------------------
  # Access Policies
  # ---------------------------
  dynamic "access_policy" {

    for_each = lookup(each.value, "access_policies", [])

    content {

    tenant_id = access_policy.value.tenant_id
    object_id = access_policy.value.object_id
    # application_id = lookup(access_policy.value, "application_id", null) #


    key_permissions = lookup(access_policy.value, "key_permissions", [])
    secret_permissions = lookup(access_policy.value, "secret_permissions", [])
    certificate_permissions = lookup(access_policy.value, "certificate_permissions", [])
    storage_permissions = lookup(access_policy.value, "storage_permissions", [])
    }
  }

#   dynamic "access_policy" {

#     for_each = lookup(each.value, "access_policies", [])

#     content {

#       tenant_id = access_policy.value.tenant_id
#       object_id = access_policy.value.object_id

#       application_id = lookup(access_policy.value, "application_id", null)

#       key_permissions = lookup(
#         access_policy.value,
#         "key_permissions",
#         []
#       )

#       secret_permissions = lookup(
#         access_policy.value,
#         "secret_permissions",
#         []
#       )

#       certificate_permissions = lookup(
#         access_policy.value,
#         "certificate_permissions",
#         []
#       )

#       storage_permissions = lookup(
#         access_policy.value,
#         "storage_permissions",
#         []
#       )
#     }
#   }

  # ---------------------------
  # Network ACLS
  # ---------------------------

  dynamic "network_acls" {

    for_each = lookup(each.value, "network_acls", null) != null ? [each.value.network_acls] : []

    content {

      bypass         = network_acls.value.bypass
      default_action = network_acls.value.default_action

      ip_rules = lookup(
        network_acls.value,
        "ip_rules",
        []
      )

      virtual_network_subnet_ids = lookup(
        network_acls.value,
        "virtual_network_subnet_ids",
        []
      )
    }
  }

  tags = each.value.tags

  lifecycle {
    precondition {
      condition     = alltrue([for v in values(each.value.tags) : trimspace(v) != ""])
      error_message = "RG '${each.key}' creation blocked: one or more required tags are empty."
    }
    ignore_changes = [
      tags["hidden-link: /app-insights-resource-id"],
      tags["hidden-link: /app-insights-conn-string"],
      tags["hidden-link: /app-insights-instrumentation-key"]
    ]
  }
}