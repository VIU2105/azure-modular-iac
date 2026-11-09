variable "windows_web_app_ids" {
  description = "Map of Windows Web App IDs"
  type        = map(string)
}

variable "windows_web_app_slots" {
  description = "Map of Windows Web App Slots"
  type = map(object({

    # -------- Required --------
    name                  = string
    existing_web_app_name = string

    # -------- Optional overrides --------
    service_plan_id = optional(string)

    enabled                       = optional(bool, true)
    https_only                    = optional(bool)
    public_network_access_enabled = optional(bool)
    client_affinity_enabled       = optional(bool)
    client_certificate_mode          = optional(string) # Required | Optional | OptionalInteractiveUser
    client_certificate_enabled = optional(bool) 
    builtin_logging_enabled = optional(bool) 
    ftp_publish_basic_authentication_enabled = optional(bool)
    webdeploy_publish_basic_authentication_enabled = optional(bool)

    # -------- App Settings --------
    app_settings = optional(map(string), {})

    connection_strings = optional(list(object({
      name  = string
      type  = string
      value = string
    })), [])
    # -------- Identity --------
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))

    key_vault_reference_identity_id = optional(string)
    
    # -------- Authentication (v1) --------
    auth_settings = optional(object({
      enabled                       = bool
      default_provider              = optional(string)
      issuer                        = optional(string)
      token_store_enabled           = optional(bool)
      unauthenticated_client_action = optional(string)
    }))

    # -------- Authentication (v2) --------
    auth_settings_v2 = optional(object({
      auth_enabled           = optional(bool)
      runtime_version        = optional(string)
      require_authentication = optional(bool)
      unauthenticated_action = optional(string)
      require_https          = optional(bool)

      active_directory_v2 = optional(object({
        client_id            = string
        tenant_auth_endpoint = string
        allowed_audiences    = optional(list(string))
      }))

      login = object({
        logout_endpoint              = optional(string)
        token_store_enabled          = optional(bool)
        token_refresh_extension_time = optional(number)
      })
    }))
    
     #Blocks of type "sticky_settings" are not expected here

    site_config = optional(object({
      always_on           = optional(bool)
      http2_enabled       = optional(bool)
      minimum_tls_version = optional(string)
      use_32_bit_worker   = optional(bool)
      ftps_state          = optional(string)
      health_check_path   = optional(string)
      worker_count        = optional(number)
      application_insights_connection_string = optional(string)
      application_insights_key               = optional(string)

      # Not part of Windows Web App Slots
      #pre_warmed_instance_count = optional(number) 
      #app_scale_limit     = optional(number)
      #ip_restriction_default_action     = optional(string)
      #scm_ip_restriction_default_action = optional(string)

    }))

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
      for s in values(var.windows_web_app_slots) : [
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
    error_message = "Each Windows Web App Slot must include non-empty mandatory tag values."
  }
}