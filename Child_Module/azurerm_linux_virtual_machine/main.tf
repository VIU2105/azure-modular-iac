

# Linux Virtual Machine

resource "azurerm_linux_virtual_machine" "linux_vm" {

  for_each = var.linux_virtual_machines

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  size = each.value.size

#   network_interface_ids = [for nic_name in each.value.existing_nic_names : var.network_interfaces_ids[nic_name]]
  network_interface_ids = [for nic_name in each.value.existing_nic_names : lookup(var.network_interfaces_ids, nic_name, null)]
  admin_username = lookup(each.value, "admin_username", null)

  admin_password = lookup(each.value, "admin_password", null)

  disable_password_authentication = lookup(each.value, "disable_password_authentication", false)

  computer_name = lookup(each.value, "computer_name", null)

  availability_set_id           = lookup(each.value, "availability_set_id", null)
  capacity_reservation_group_id = lookup(each.value, "capacity_reservation_group_id", null)
  proximity_placement_group_id  = lookup(each.value, "proximity_placement_group_id", null)
  
  reboot_setting = lookup(each.value, "reboot_setting", "Never")

  allow_extension_operations = lookup(
    each.value,
    "allow_extension_operations",
    true
  )

  provision_vm_agent = lookup(
    each.value,
    "provision_vm_agent",
    true
  )

  patch_mode            = lookup(each.value, "patch_mode", null)
  patch_assessment_mode = lookup(each.value, "patch_assessment_mode", null)

  priority        = lookup(each.value, "priority", null)
  eviction_policy = lookup(each.value, "eviction_policy", null)
  max_bid_price   = lookup(each.value, "max_bid_price", null)

  license_type = lookup(each.value, "license_type", null)

  encryption_at_host_enabled = lookup(each.value,"encryption_at_host_enabled", false)

  secure_boot_enabled = lookup(each.value, "secure_boot_enabled", null)

  vtpm_enabled = lookup(each.value, "vtpm_enabled", null)

  source_image_id    = lookup(each.value, "source_image_id", null)
  os_managed_disk_id = lookup(each.value, "os_managed_disk_id", null)

  custom_data = lookup(each.value, "custom_data", null)
  user_data   = lookup(each.value, "user_data", null)

  zone = lookup(each.value, "zone", null)

  # SSH Key

  dynamic "admin_ssh_key" {

    for_each = lookup(each.value, "admin_ssh_keys", [])

    content {

      username   = admin_ssh_key.value.username
      public_key = admin_ssh_key.value.public_key
    }
  }

  # OS Disk

  os_disk {

    caching              = each.value.os_disk.caching
    storage_account_type = lookup(each.value.os_disk, "storage_account_type", null)

    disk_size_gb = lookup(each.value.os_disk, "disk_size_gb", null)

    name = lookup(each.value.os_disk, "name", null)

    disk_encryption_set_id = lookup(each.value.os_disk, "disk_encryption_set_id", null)

    secure_vm_disk_encryption_set_id = lookup(
      each.value.os_disk,
      "secure_vm_disk_encryption_set_id",
      null
    )

    security_encryption_type = lookup(
      each.value.os_disk,
      "security_encryption_type",
      null
    )

    write_accelerator_enabled = lookup(
      each.value.os_disk,
      "write_accelerator_enabled",
      null
    )

    dynamic "diff_disk_settings" {

      for_each = lookup(each.value.os_disk, "diff_disk_settings", null) != null ? [each.value.os_disk.diff_disk_settings] : []

      content {

        option = diff_disk_settings.value.option

        placement = lookup(
          diff_disk_settings.value,
          "placement",
          null
        )
      }
    }
  }

  # Image

  dynamic "source_image_reference" {

    for_each = lookup(each.value, "source_image_reference", null) != null ? [each.value.source_image_reference] : []
    content {

      publisher = source_image_reference.value.publisher
      offer     = source_image_reference.value.offer
      sku       = source_image_reference.value.sku
      version   = source_image_reference.value.version
    }
  }

  # Identity

  dynamic "identity" {

    for_each = lookup(each.value, "identity", null) != null ? [each.value.identity] : []

    content {

      type = identity.value.type

      identity_ids = lookup(
        identity.value,
        "identity_ids",
        null
      )
    }
  }

  # Additional Capabilities

  dynamic "additional_capabilities" {

    for_each = lookup(each.value, "additional_capabilities", null) != null ? [each.value.additional_capabilities] : []

    content {

      ultra_ssd_enabled = lookup(
        additional_capabilities.value,
        "ultra_ssd_enabled",
        false
      )

      hibernation_enabled = lookup(
        additional_capabilities.value,
        "hibernation_enabled",
        false
      )
    }
  }

  # Boot Diagnostics

  dynamic "boot_diagnostics" {

    for_each = lookup(each.value, "boot_diagnostics", null) != null ? [each.value.boot_diagnostics] : []

    content {

      storage_account_uri = lookup(
        boot_diagnostics.value,
        "storage_account_uri",
        null
      )
    }
  }

  # Plan

  dynamic "plan" {

    for_each = lookup(each.value, "plan", null) != null ? [each.value.plan] : []

    content {

      name      = plan.value.name
      publisher = plan.value.publisher
      product   = plan.value.product
    }
  }

  tags = each.value.tags

  lifecycle {
    precondition {
      # condition     = alltrue([for v in values(each.value.tags) : trimspace(v) != ""])
      condition = alltrue([for v in values(each.value.tags) : v == null ? true : trimspace(v) != ""]) # it will not check for optional tag values

      error_message = "RG '${each.key}' creation blocked: one or more required tags are empty."
    }
    ignore_changes = [ additional_capabilities , identity[0].identity_ids, vtpm_enabled, admin_password]
  }

}

output "linux_virtual_machine_ids" {

  value = { for _, vm in azurerm_linux_virtual_machine.linux_vm : vm.name => vm.id }
}
