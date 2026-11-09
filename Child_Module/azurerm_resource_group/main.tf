resource "azurerm_resource_group" "resource_groups" {
  for_each   = var.rg_name
  name       = each.value.name
  location   = each.value.location
  tags       = each.value.tags
  managed_by = each.value.managed_by

  lifecycle {
    precondition {
      condition     = alltrue([for v in values(each.value.tags) : trimspace(v) != ""])
      error_message = "RG '${each.key}' creation blocked: one or more required tags are empty."
    }
  }
}
