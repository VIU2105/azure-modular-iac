# NIC Configuration

variable "network_interfaces_ids" {

  type = map(string)
}

# Windows Virtual Machines Configuration
variable "windows_virtual_machines" {

  description = "Map of Windows Virtual Machines"

  type = map(object({

    name                = string
    resource_group_name = string
    location            = string

    size = string

    existing_nic_names  = list(string)  # this value we need to share from the existing NICs

    admin_username = optional(string)
    admin_password = optional(string)

    computer_name = optional(string)

    availability_set_id           = optional(string)
    capacity_reservation_group_id = optional(string)

    proximity_placement_group_id = optional(string)

    allow_extension_operations = optional(bool,true)

    provision_vm_agent = optional(bool,true)

    automatic_updates_enabled = optional(bool,true)

    patch_mode            = optional(string)
    patch_assessment_mode = optional(string)

    encryption_at_host_enabled = optional(bool)

    secure_boot_enabled = optional(bool)
    vtpm_enabled        = optional(bool)

    source_image_id    = optional(string)
    os_managed_disk_id = optional(string)

    custom_data = optional(string)
    user_data   = optional(string)

    timezone = optional(string)
    zone     = optional(string)

    priority        = optional(string)
    eviction_policy = optional(string)
    max_bid_price   = optional(number)

    license_type = optional(string)

    os_disk = object({

      caching = string

      storage_account_type = optional(string)

      disk_size_gb = optional(number)

      name = optional(string)

      disk_encryption_set_id = optional(string)

      secure_vm_disk_encryption_set_id = optional(string)

      security_encryption_type = optional(string)

      write_accelerator_enabled = optional(bool)

      diff_disk_settings = optional(object({

        option    = string
        placement = optional(string)

      }))
    })

    source_image_reference = optional(object({

      publisher = string
      offer     = string
      sku       = string
      version   = string

    }))

    identity = optional(object({

      type = string

      identity_ids = optional(list(string))

    }))

    additional_capabilities = optional(object({

      ultra_ssd_enabled   = optional(bool)
      hibernation_enabled = optional(bool)

    }))

    boot_diagnostics = optional(object({

      storage_account_uri = optional(string)

    }))

    plan = optional(object({

      name      = string
      publisher = string
      product   = string

    }))

    tags = object({
      owner           = optional(string) # optional
      ApplicationName = string
      CreatedBy       = optional(string) # optional
      BusinessService = optional(string) # optional
      Environment     = string
      OpsTeam         = string
      Portfolio       = string
      PortfolioArea   = string
      RequestedBy     = string
      Vendor          = string
    })
  }))
 # ------------------------------------------------------------
  # Validation – same as all resources to ensure mandatory tags are populated
  # ------------------------------------------------------------
  validation {
    condition = alltrue(flatten([
      for w in values(var.windows_virtual_machine) : [
        # trimspace(w.tags.owner) != "",
        trimspace(w.tags.ApplicationName) != "",
        # trimspace(w.tags.CreatedBy) != "",
        # trimspace(w.tags.BusinessService) != "",
        trimspace(w.tags.Environment) != "",
        trimspace(w.tags.OpsTeam) != "",
        trimspace(w.tags.Portfolio) != "",
        trimspace(w.tags.PortfolioArea) != "",
        trimspace(w.tags.RequestedBy) != "",
        trimspace(w.tags.Vendor) != ""
      ]
    ]))
    error_message = "Each Windows Virtual Machine must include non-empty values for all mandatory tags."
  }
}


    