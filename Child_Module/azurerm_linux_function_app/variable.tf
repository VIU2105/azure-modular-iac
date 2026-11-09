# ------------------------------------------------------------
# Service Plan IDs (same as Windows)
# ------------------------------------------------------------
variable "service_app_ids" {
  type = map(string)
}

# ------------------------------------------------------------
# Linux Function Apps
# ------------------------------------------------------------
variable "linux_function_apps" {
  description = "Map of Linux Function Apps to create"
  type = map(object({

    # -------- Service Plan reference --------
    existing_sp_name = string
    existing_sp_rg   = string

    # -------- Required --------
    name                = string
    resource_group_name = string
    location            = string

    # -------- Storage wiring --------
    storage_account_name = optional(string)
    rg_name_stg          = optional(string)
    # storage_account_access_key intentionally omitted (managed by data source)

    # -------- App & platform --------
    functions_extension_version      = optional(string)
    https_only                       = optional(bool)
    public_network_access_enabled    = optional(bool, true)
    enabled                          = optional(bool, true)
    
    vnet_image_pull_enabled = optional(bool)
    client_certificate_enabled = optional(bool)
    client_certificate_mode    = optional(string) # Required | Optional | OptionalInteractiveUser
    builtin_logging_enabled = optional(bool) 
    ftp_publish_basic_authentication_enabled = optional(bool)
    webdeploy_publish_basic_authentication_enabled = optional(bool)
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

    # -------- Identity --------
    identity = optional(object({
      type         = string                      # SystemAssigned | UserAssigned | Both
      identity_ids = optional(list(string), [])
    }))

    key_vault_reference_identity_id = optional(string)

    # -------- App settings --------
    app_settings = optional(map(string), {})

    # -------- Site Config (Linux specific) --------

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
      ip_restriction_default_action     = optional(string)
      scm_ip_restriction_default_action = optional(string)

      # -------- Linux runtime --------
      application_stack = optional(object({
        dotnet_version = optional(string)
        node_version   = optional(string)
        python_version = optional(string)
        java_version   = optional(string)
      }))
    }))


    # -------- Authentication (v1) --------
    auth_settings = optional(object({
      enabled                         = bool
      default_provider                = optional(string)
      issuer                          = optional(string)
      token_store_enabled             = optional(bool)
      token_refresh_extension_hours   = optional(number)
      unauthenticated_client_action   = optional(string)
      allowed_external_redirect_urls  = optional(list(string))
      additional_login_parameters     = optional(map(string))
    }))

    # -------- Authentication (v2) --------
    auth_settings_v2 = optional(object({
      auth_enabled              = optional(bool, false)
      runtime_version           = optional(string, "~1")
      require_https             = optional(bool, true)
      require_authentication    = optional(bool, false)
      unauthenticated_action    = optional(string, "RedirectToLoginPage")

      active_directory_v2 = optional(object({
        client_id                            = string
        tenant_auth_endpoint                 = string
        client_secret_setting_name           = optional(string)
        client_secret_certificate_thumbprint = optional(string)
        jwt_allowed_groups                   = optional(list(string))
        jwt_allowed_client_applications      = optional(list(string))
        www_authentication_disabled          = optional(bool)
        allowed_groups                       = optional(list(string))
        allowed_identities                   = optional(list(string))
        allowed_applications                 = optional(list(string))
        login_parameters                     = optional(map(string))
        allowed_audiences                    = optional(list(string))
      }))

      login = object({
        logout_endpoint              = optional(string)
        token_store_enabled          = optional(bool, false)
        token_refresh_extension_time = optional(number, 72)
      })
    }))
  }))

  # ------------------------------------------------------------
  # Validation (same rule as Windows)
  # ------------------------------------------------------------
  validation {
    condition = alltrue(flatten([
      for l in values(var.linux_function_apps) : [
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
    error_message = "Each Linux Function App must include non-empty tag values for all mandatory tags."
  }
}
