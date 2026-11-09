variable "app_service_environment_v3" {
  description = "Map of ASEv3 definitions"
  type = map(object({
    name                                   = string
    resource_group_name                    = string
    subnet_id                              = string
    allow_new_private_endpoint_connections = optional(bool)
    internal_load_balancing_mode           = optional(string) # "None" or "Web, Publishing"
    remote_debugging_enabled               = optional(bool)
    dedicated_host_count                   = optional(number) # 2
    zone_redundant                         = optional(bool)
    cluster_settings = optional(list(object({
      name  = string
      value = string
    })))
    tags = object({
      # owner           = string # optional
      ApplicationName = string
      # CreatedBy       = string #optional
      BusinessService = string #optional
      Environment     = string
      OpsTeam         = string
      Portfolio       = string
      PortfolioArea   = string
      RequestedBy     = string
      Vendor          = string
    })

  }))
  validation {
    condition = alltrue(flatten([
      for w in values(var.app_service_environment_v3) : [
        # trimspace(w.tags.owner) != "",
        trimspace(w.tags.ApplicationName) != "",
        # trimspace(w.tags.CreatedBy) != "",
        trimspace(w.tags.BusinessService) != "",
        trimspace(w.tags.Environment) != "",
        trimspace(w.tags.OpsTeam) != "",
        trimspace(w.tags.Portfolio) != "",
        trimspace(w.tags.PortfolioArea) != "",
        trimspace(w.tags.RequestedBy) != "",
        trimspace(w.tags.Vendor) != ""
      ]
    ]))
    error_message = "Each workload must include non-empty values for: owner, ApplicationName, CreatedBy, BusinessService, Environment, OpsTeam, Portfolio, PortfolioArea, RequestedBy, Vendor."
  }

}
