variable "service_env_app_ids" {
    type = map(string)
}

variable "service_plans" {
  description = <<-EOT
    Map of App Service Plans to create. Keys are arbitrary plan keys.
    All resource arguments are supported; optional attributes can be omitted.
  EOT

  type = map(object({
    # Required
    name                = string
    location            = string
    resource_group_name = string
    os_type             = string                         # Windows | Linux | WindowsContainer
    sku_name            = string
    tags                = object({                        # We are having azure policy that every resource will have the tags
      owner           = optional(string)                            # optional
      ApplicationName = string
      CreatedBy       = optional(string)                            #optional
      BusinessService = optional(string)                            #optional
      Environment     = string
      OpsTeam         = string
      Portfolio       = string
      PortfolioArea   = string
      RequestedBy     = string
      Vendor          = string
    })                   
    # Optional
    app_service_environment_id      = optional(string)   # Required if using Isolated v2 SKUs
    premium_plan_auto_scale_enabled = optional(bool)     # Premium SKUs only
    maximum_elastic_worker_count    = optional(number)   # EP SKUs or Premium with auto-scale enabled
    worker_count                    = optional(number)   # >= 1 for manual instance count
    per_site_scaling_enabled        = optional(bool)
    zone_balancing_enabled          = optional(bool)

    # Map of existing ASE v3 lookups. Key is an arbitrary label (ase_key) you’ll reference from service_plans.
    # To get the App Service Environment ID
    existing_ase_name = string 
    existing_ase_rg = string
  }))
  # Condition to check wether the tags value is provided as per the policy
 validation {
    condition = alltrue(flatten([
      for w in values(var.service_plans) : [
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
    error_message = "Each workload must include non-empty values for: owner, ApplicationName, CreatedBy, BusinessService, Environment, OpsTeam, Portfolio, PortfolioArea, RequestedBy, Vendor."
}
}

