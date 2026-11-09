data "azurerm_key_vault" "kv" {
  for_each = var.key_vault_access_policy
  name                = each.value.key_vault_name
  resource_group_name = each.value.key_vault_rg_name
}

resource "azurerm_key_vault_access_policy" "funcapp_policy" {

  for_each = var.key_vault_access_policy
  key_vault_id = data.azurerm_key_vault.kv[each.key].id

  tenant_id = each.value.tenant_id
  object_id = var.function_app_principal_ids[each.value.existing_func_app_name]

  secret_permissions = each.value.secret_permissions

  key_permissions = each.value.key_permissions

  certificate_permissions = each.value.certificate_permissions
}

# Output the principal IDs of the Linux Function Apps