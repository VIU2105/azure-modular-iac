variable "linux_web_app_ids" {
  type = map(string)
}

variable "linux_web_app_slots" {
  description = "Map of Linux Web App Slots"
  type = map(object({
    name     = string
    existing_linux_web_app_name = string   # reference key of parent linux web app

    enabled                       = optional(bool)
    https_only                    = optional(bool)
    public_network_access_enabled = optional(bool)

    client_affinity_enabled    = optional(bool)
    client_certificate_enabled = optional(bool)
    client_certificate_mode    = optional(string)

    key_vault_reference_identity_id = optional(string)
    vnet_image_pull_enabled         = optional(bool)

    ftp_publish_basic_authentication_enabled       = optional(bool)
    webdeploy_publish_basic_authentication_enabled = optional(bool)

    service_plan_id = optional(string)

    app_settings = optional(map(string))

    connection_strings = optional(list(object({
      name  = string
      type  = string
      value = string
    })),[])  # here we are using a list of object to hume by default ye value di hai []

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))

    auth_settings = optional(object({
      enabled                       = bool
      issuer                        = optional(string)
      default_provider              = optional(string)
      token_store_enabled           = optional(bool)
      unauthenticated_client_action = optional(string)
    }))

    auth_settings_v2 = optional(object({
      auth_enabled           = optional(bool)
      runtime_version        = optional(string)
      require_https          = optional(bool)
      require_authentication = optional(bool)
      unauthenticated_action = optional(string)

      login = object({
        logout_endpoint              = optional(string)
        token_store_enabled          = optional(bool)
        token_refresh_extension_time = optional(number)
      })
    }))

    site_config = object({
      always_on           = optional(bool)
      http2_enabled       = optional(bool)
      minimum_tls_version = optional(string)
      ftps_state          = optional(string)
      health_check_path   = optional(string)
      worker_count        = optional(number)

      ip_restriction_default_action     = optional(string)
      scm_ip_restriction_default_action = optional(string)

      application_stack = optional(object({
        dotnet_version = optional(string)
        node_version   = optional(string)
        python_version = optional(string)
        java_version   = optional(string)
      }))
    })

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

  validation {
    condition = alltrue(flatten([
      for s in values(var.linux_web_app_slots) : [
        trimspace(s.tags.owner) != "",
        trimspace(s.tags.ApplicationName) != "",
        trimspace(s.tags.CreatedBy) != "",
        trimspace(s.tags.BusinessService) != "",
        trimspace(s.tags.Environment) != "",
        trimspace(s.tags.OpsTeam) != "",
        trimspace(s.tags.Portfolio) != "",
        trimspace(s.tags.PortfolioArea) != "",
        trimspace(s.tags.RequestedBy) != "",
        trimspace(s.tags.Vendor) != ""
      ]
    ]))
    error_message = "Each Linux Web App Slot must include non-empty mandatory tag values."
  }

}