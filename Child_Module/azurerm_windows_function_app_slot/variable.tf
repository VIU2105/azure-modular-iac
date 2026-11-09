variable "windows_function_ids" {
  type = map(string)
}

variable "windows_function_app_slots" {
  description = "Map of Windows Function App Slots to create (provider v4+)."
  type = map(object({
    # -------- Required --------
    name            = string
    # function_app_id = string # Using the data block
    # -----------Data Block----------
    #To get the Function App
    existing_func_app_name = string
    existing_func_app_rg   = string
    # function_app_id = string

    # Required block (fields inside are optional)
    site_config = object({
      # Common toggles
      always_on                         = optional(bool,false)
      http2_enabled                     = optional(bool)
      minimum_tls_version               = optional(string) # 1.0 | 1.1 | 1.2 | 1.3
      use_32_bit_worker                 = optional(bool)
      ftps_state                        = optional(string) # AllAllowed | FtpsOnly | Disabled
      health_check_path                 = optional(string)
      health_check_eviction_time_in_min = optional(number)
      pre_warmed_instance_count         = optional(number)
      app_scale_limit                   = optional(number)
      worker_count                      = optional(number)
      application_insights_connection_string = optional(string)
      application_insights_key               = optional(string)
      load_balancing_mode               = optional(string) # WeightedRoundRobin | LeastRequests | LeastResponseTime | WeightedTotalTraffic | RequestHash | PerSiteRoundRobin
      managed_pipeline_mode             = optional(string) # Integrated | Classic
      runtime_scale_monitoring_enabled  = optional(bool)
      scm_minimum_tls_version           = optional(string) # 1.0 | 1.1 | 1.2 | 1.3
      scm_use_main_ip_restriction       = optional(bool)

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

    # -------- Optional top-level arguments --------
    service_plan_id                         = optional(string)
    app_settings  = optional(map(string))

    auth_settings = optional(object({
      enabled = bool
      active_directory = optional(object({
        client_id                  = string
        allowed_audiences          = optional(list(string))
        client_secret              = optional(string)
        client_secret_setting_name = optional(string)
      }))
      additional_login_parameters    = optional(map(string))
      allowed_external_redirect_urls = optional(list(string))
      default_provider               = optional(string)
      issuer                         = optional(string)
      runtime_version                = optional(string)
      token_refresh_extension_hours  = optional(number)
      token_store_enabled            = optional(bool)
      unauthenticated_client_action = optional(string) # RedirectToLoginPage | AllowAnonymous
    }))

    auth_settings_v2 = optional(object({
      auth_enabled           = optional(bool)
      runtime_version        = optional(string) # defaults to ~1 in resource
      config_file_path       = optional(string)
      require_authentication = optional(bool)
      unauthenticated_action = optional(string) # RedirectToLoginPage | AllowAnonymous | Return401 | Return403
      default_provider       = optional(string) # apple | azureactivedirectory | facebook | github | google | twitter | <custom oidc name>
      excluded_paths         = optional(list(string))
      require_https          = optional(bool)
      http_route_api_prefix  = optional(string)
      forward_proxy_convention               = optional(string) # NoProxy | Standard | Custom
      forward_proxy_custom_host_header_name  = optional(string)
      forward_proxy_custom_scheme_header_name= optional(string)

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

      # Required sub-block when auth_settings_v2 is supplied
      login = object({
        logout_endpoint                 = optional(string)
        token_store_enabled             = optional(bool)
        token_refresh_extension_time    = optional(number)
        token_store_path                = optional(string)
        token_store_sas_setting_name    = optional(string)
        preserve_url_fragments_for_logins = optional(bool)
        allowed_external_redirect_urls  = optional(list(string))
        cookie_expiration_convention    = optional(string)
        cookie_expiration_time          = optional(string) # HH:MM:SS
        validate_nonce                  = optional(bool)
        nonce_expiration_time           = optional(string) # HH:MM:SS
      })
    }))

    builtin_logging_enabled                 = optional(bool)
    client_certificate_mode                 = optional(string)
    client_certificate_enabled              = optional(bool)
    connection_strings = optional(list(object({
      name  = string
      type  = string
      value = string
    })))
    daily_memory_time_quota                 = optional(number)
    enabled                                 = optional(bool)
    functions_extension_version             = optional(string)
    https_only                              = optional(bool)
    public_network_access_enabled           = optional(bool)
    ftp_publish_basic_authentication_enabled = optional(bool)
    webdeploy_publish_basic_authentication_enabled = optional(bool)

    identity = optional(object({
      type         = string  # SystemAssigned | UserAssigned | SystemAssigned, UserAssigned
      identity_ids = optional(list(string))
    }))

    # Storage mounting (Azure Files)
    storage_accounts = optional(list(object({
      name         = string
      type         = string           # AzureFiles
      account_name = string
      access_key   = string
      share_name   = string
      mount_path   = optional(string)
    })))

    storage_account_name            = optional(string)
    rg_name_stg                     = optional(string)
    # storage_account_access_key      = optional(string)  # conflict with storage_uses_managed_identity
    virtual_network_backup_restore_enabled = optional(bool)
    virtual_network_subnet_id              = optional(string) # cannot be used with separate swift_connection for same app/slot
    vnet_image_pull_enabled                = optional(bool)

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
  }))
  validation {
    condition = alltrue(flatten([
      for w in values(var.windows_function_app_slots) : [
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