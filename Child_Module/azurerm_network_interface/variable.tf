variable "network_interfaces" {
  type = map(object({

    name                = string
    resource_group_name = string
    location            = string
    accelerated_networking_enabled = optional(bool)
    
    ip_configurations = list(object({

      name                          = string
      subnet_id                     = string
      private_ip_address_allocation = string

      private_ip_address  = optional(string)
      public_ip_address_id = optional(string)

      primary = optional(bool)
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
      for w in values(var.network_interfaces) : [
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
    error_message = "Each Network Interface must include non-empty values for all mandatory tags."
  }
}
