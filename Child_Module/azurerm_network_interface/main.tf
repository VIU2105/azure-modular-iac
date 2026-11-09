resource "azurerm_network_interface" "network_interface" {

  for_each = var.network_interfaces

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  accelerated_networking_enabled = lookup(each.value, "accelerated_networking_enabled", false)

  dynamic "ip_configuration" {

    for_each = each.value.ip_configurations

    content {

      name                          = ip_configuration.value.name
      subnet_id                     = ip_configuration.value.subnet_id
      private_ip_address_allocation = ip_configuration.value.private_ip_address_allocation

      private_ip_address = lookup(
        ip_configuration.value,
        "private_ip_address",
        null
      )

      public_ip_address_id = lookup(
        ip_configuration.value,
        "public_ip_address_id",
        null
      )

      primary = lookup(
        ip_configuration.value,
        "primary",
        null
      )
    }
  }

  tags = each.value.tags

  lifecycle {
    precondition {
      # condition     = alltrue([for v in values(each.value.tags) : trimspace(v) != ""])
      condition     = alltrue([for v in values(each.value.tags) : v == null ? true : trimspace(v) != ""]) # it will not check for optional tag values
      
      error_message = "RG '${each.key}' creation blocked: one or more required tags are empty."
    }
  ignore_changes = [dns_servers]
  }
}

output "azure_network_interfaces_ids" {

  value = {
    for _, nic in azurerm_network_interface.network_interface :
    nic.name => nic.id
  }
}