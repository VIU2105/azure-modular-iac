variable "key_vaults" {

  type = map(object({

    name                = string
    location            = string
    resource_group_name = string

    # tenant_id = string

    sku_name = string

    # Core Features
    enabled_for_deployment          = optional(bool)
    enabled_for_disk_encryption     = optional(bool)
    enabled_for_template_deployment = optional(bool)

    rbac_authorization_enabled  = optional(bool, false)
    public_network_access_enabled = optional(bool, false)

    purge_protection_enabled = optional(bool, false)

    soft_delete_retention_days = optional(number, 90)

    # Network
    network_acls = optional(object({

      bypass         = string
      default_action = string

      ip_rules = optional(list(string), [])

      virtual_network_subnet_ids = optional(list(string), [])

    }))

    # Access Policies
    access_policies = optional(list(object({

      tenant_id = string
      object_id = string

     #   application_id = optional(string)

      key_permissions = optional(list(string), [])

      secret_permissions = optional(list(string), [])

      certificate_permissions = optional(list(string), [])

      storage_permissions = optional(list(string), [])

    })), [])

    tags = object({
      owner           = string
      ApplicationName = string
      CreatedBy       = string
      BusinessService = string
      Environment     = string
      OpsTeam         = string
      Portfolio       = string
      PortfolioArea   = string
      RequestedBy     = string
      Vendor          = string
    })
  }))

  # ------------------------------------------------------------
  # Validation (same rule as Windows)
  # ------------------------------------------------------------
  validation {
    condition = alltrue(flatten([
      for l in values(var.key_vaults) : [
        trimspace(l.tags.owner) != "",
        trimspace(l.tags.ApplicationName) != "",
        trimspace(l.tags.CreatedBy) != "",
        trimspace(l.tags.BusinessService) != "",
        trimspace(l.tags.Environment) != "",
        trimspace(l.tags.OpsTeam) != "",
        trimspace(l.tags.Portfolio) != "",
        trimspace(l.tags.PortfolioArea) != "",
        trimspace(l.tags.RequestedBy) != "",
        trimspace(l.tags.Vendor) != ""
      ]
    ]))
    error_message = "Each Key vaults must include non-empty tag values for all mandatory tags."
  }
}
