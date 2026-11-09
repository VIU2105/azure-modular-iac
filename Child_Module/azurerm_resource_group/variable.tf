variable "rg_name" {

  description = "Collection of resources to create; each must include the full mandatory tag set."
  type = map(object({
    name     = string
    location = string
    tags = object({
      owner           = string # optional
      ApplicationName = string
      CreatedBy       = string #optional
      BusinessService = string #optional
      Environment     = string
      OpsTeam         = string
      Portfolio       = string
      PortfolioArea   = string
      RequestedBy     = string
      Vendor          = string
    })

    managed_by = optional(string)
  }))


  # No default -> callers MUST populate every tag for each item

  # Validate all items: all tag values must be non-empty
  validation {
    condition = alltrue(flatten([
      for w in values(var.rg_name) : [
        trimspace(w.tags.owner) != "",
        trimspace(w.tags.ApplicationName) != "",
        trimspace(w.tags.CreatedBy) != "",
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