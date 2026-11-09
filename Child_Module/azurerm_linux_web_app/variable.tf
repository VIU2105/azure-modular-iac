# ------------------------------------------------------------
# Service Plan IDs (shared across modules)
# ------------------------------------------------------------
variable "service_app_ids" {
  description = "Map of App Service Plan IDs"
  type        = map(string)
}

# ------------------------------------------------------------
# Linux Web Apps
# ------------------------------------------------------------

variable "linux_web_apps" {
  description = "Map of Linux Web Apps to create"
  type = map(object({

    existing_sp_name = string

    name                = string
    resource_group_name = string
    location            = string

    enabled                       = optional(bool, true)
    https_only                    = optional(bool, true)
    public_network_access_enabled = optional(bool)
    client_affinity_enabled       = optional(bool)
    vnet_image_pull_enabled       = optional(bool)
    client_certificate_enabled = optional(bool)
    client_certificate_mode    = optional(string)

    ftp_publish_basic_authentication_enabled       = optional(bool)
    webdeploy_publish_basic_authentication_enabled = optional(bool)

    app_settings = optional(map(string), {})

    connection_strings = optional(list(object({
      name  = string
      type  = string
      value = string
    })), [])

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))

    key_vault_reference_identity_id = optional(string)

    auth_settings = optional(object({
      enabled                       = bool
      default_provider              = optional(string)
      issuer                        = optional(string)
      token_store_enabled           = optional(bool)
      unauthenticated_client_action = optional(string)
    }))

    auth_settings_v2 = optional(object({
      auth_enabled              = optional(bool, false)
      runtime_version           = optional(string, "~1")
      require_https             = optional(bool, true)
      require_authentication    = optional(bool, false)
      unauthenticated_action    = optional(string)

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

    site_config = optional(object({
      always_on           = optional(bool)
      http2_enabled       = optional(bool)
      minimum_tls_version = optional(string)
      use_32_bit_worker   = optional(bool)
      ftps_state          = optional(string)
      health_check_path   = optional(string)
      worker_count        = optional(number)
      #   application_insights_connection_string = optional(string)
      #   application_insights_key               = optional(string)
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
      for s in values(var.linux_web_apps) : [
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
    error_message = "Each Linux Web App must include non-empty mandatory tags."
  }
}