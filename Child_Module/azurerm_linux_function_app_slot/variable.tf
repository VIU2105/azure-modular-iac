variable "linux_function_ids" {
  type = map(string)
}

variable "linux_function_app_slots" {
  description = "Map of Linux Function App Slots"
  type = map(object({

    # -------- Required --------
    name = string

    existing_func_app_name = string
    existing_func_app_rg   = string

    # Required block (fields inside are optional)
    site_config = object({
      # Common toggles
      always_on                              = optional(bool, false)
      http2_enabled                          = optional(bool)
      minimum_tls_version                    = optional(string) # 1.0 | 1.1 | 1.2 | 1.3
      use_32_bit_worker                      = optional(bool)
      ftps_state                             = optional(string) # AllAllowed | FtpsOnly | Disabled
      health_check_path                      = optional(string)
      health_check_eviction_time_in_min      = optional(number)
      pre_warmed_instance_count              = optional(number)
      app_scale_limit                        = optional(number)
      worker_count                           = optional(number)
      application_insights_connection_string = optional(string)
      application_insights_key               = optional(string)
      load_balancing_mode                    = optional(string) # WeightedRoundRobin | LeastRequests | LeastResponseTime | WeightedTotalTraffic | RequestHash | PerSiteRoundRobin
      managed_pipeline_mode                  = optional(string) # Integrated | Classic
      runtime_scale_monitoring_enabled       = optional(bool)
      scm_minimum_tls_version                = optional(string) # 1.0 | 1.1 | 1.2 | 1.3
      scm_use_main_ip_restriction            = optional(bool)

      # Application stack (Windows Functions)
      application_stack = optional(object({
        dotnet_version              = optional(string) # v3.0,v4.0,v6.0,v7.0,v8.0,v9.0,v10.0
        use_dotnet_isolated_runtime = optional(bool)
        java_version                = optional(string) # 1.8, 11, 17, 21
        node_version                = optional(string) # ~12,~14,~16,~18,~20,~22,~24
        powershell_core_version     = optional(string) # 7,7.2,7.4
        use_custom_runtime          = optional(bool)
      }))

      # CORS
      cors = optional(object({
        allowed_origins     = list(string) # required when cors is supplied
        support_credentials = optional(bool)
      }))

      # Default actions
      ip_restriction_default_action     = optional(string) # Allow | Deny
      scm_ip_restriction_default_action = optional(string) # Allow | Deny
    })

    # -------- Optional --------
    service_plan_id = optional(string)
    app_settings    = optional(map(string), {})

    functions_extension_version                    = optional(string)
    https_only                                     = optional(bool)
    public_network_access_enabled                  = optional(bool)
    enabled                                        = optional(bool)
    vnet_image_pull_enabled                        = optional(bool)
    client_certificate_enabled                     = optional(bool)
    client_certificate_mode                        = optional(string) # Required | Optional | OptionalInteractiveUser
    ftp_publish_basic_authentication_enabled       = optional(bool)
    webdeploy_publish_basic_authentication_enabled = optional(bool)
    builtin_logging_enabled                        = optional(bool)
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))

    auth_settings = optional(object({
      enabled                       = bool
      default_provider              = optional(string)
      issuer                        = optional(string)
      token_store_enabled           = optional(bool)
      unauthenticated_client_action = optional(string)
    }))

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

    storage_account_name = optional(string)
    rg_name_stg          = optional(string)

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
      for s in values(var.linux_function_app_slots) : [
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
    error_message = "Each Linux Function App Slot must include non-empty mandatory tags."
  }
}
