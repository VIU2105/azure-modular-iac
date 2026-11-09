# ------------------------------------------------------------
# Service Plan IDs (shared across modules)
# ------------------------------------------------------------
variable "service_app_ids" {
  description = "Map of App Service Plan IDs"
  type        = map(string)
}

# ------------------------------------------------------------
# Windows Web Apps
# ------------------------------------------------------------
variable "windows_web_apps" {
  description = "Map of Windows Web Apps to create"
  type = map(object({

    # -------- Service Plan reference --------
    existing_sp_name = string
    existing_sp_rg   = optional(string)

    # -------- Required --------
    name                = string
    resource_group_name = string
    location            = string

    # -------- Core toggles --------
    enabled                       = optional(bool, true)
    https_only                    = optional(bool, true)
    public_network_access_enabled = optional(bool)
    client_affinity_enabled       = optional(bool)
    # vnet_image_pull_enabled       = optional(bool) # Not currently in Windows Web App resource 
    client_certificate_mode          = optional(string) # Required | Optional | OptionalInteractiveUser
    client_certificate_enabled = optional(bool) 
    builtin_logging_enabled = optional(bool) 
    ftp_publish_basic_authentication_enabled = optional(bool)
    webdeploy_publish_basic_authentication_enabled = optional(bool)
    
    
    # -------- App Settings --------
    app_settings = optional(map(string), {})

    # -------- Tags (mandatory – same governance) --------
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
    # -------- Connection Strings --------
    connection_strings = optional(list(object({
      name  = string
      type  = string
      value = string
    })), [])
    # -------- Identity --------
    identity = optional(object({
      type         = string                      # SystemAssigned | UserAssigned | Both
      identity_ids = optional(list(string), [])
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
      auth_enabled              = optional(bool, false)
      runtime_version           = optional(string, "~1")
      require_https             = optional(bool, true)
      require_authentication    = optional(bool, false)
      unauthenticated_action    = optional(string, "RedirectToLoginPage")

      active_directory_v2 = optional(object({
        client_id            = string
        tenant_auth_endpoint = string
        allowed_audiences    = optional(list(string))
      }))

      login = object({
        logout_endpoint              = optional(string)
        token_store_enabled          = optional(bool, false)
        token_refresh_extension_time = optional(number, 72)
      })
    }))

    # -------- Site Config (Windows specific) --------
    site_config = optional(object({
      always_on           = optional(bool, true)
      http2_enabled       = optional(bool, true)
      minimum_tls_version = optional(string, "1.2")
      ftps_state          = optional(string, "Disabled")
      use_32_bit_worker   = optional(bool, true)
      websockets_enabled = optional(bool)
      health_check_path  = optional(string)
      worker_count       = optional(number)
     #  app_scale_limit     = optional(number)        # Not present in this block Consumption/EP only

     # application_insights_connection_string = optional(string) # Not present in this block
     # application_insights_key               = optional(string) # Not present in this block
      ip_restriction_default_action  = optional(string)  # Allow/Deny
      scm_ip_restriction_default_action = optional(string)
    }))
  }))

  # ------------------------------------------------------------
  # Validation – same as all resources to ensure mandatory tags are populated
  # ------------------------------------------------------------
  validation {
    condition = alltrue(flatten([
      for w in values(var.windows_web_apps) : [
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
    error_message = "Each Windows Web App must include non-empty values for all mandatory tags."
  }
}
