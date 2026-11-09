# here we are defining the variable which has been taken from the service plan from Output BLock 

variable "service_app_ids" {
    type = map(string)
}
variable "windows_function_apps" {
  description = "Map of Windows Function Apps to create"
  type = map(object({
    # data block to get the service plan ID
    existing_sp_name = string
    existing_sp_rg = string
    # Requireds
    name                = string
    resource_group_name = string
    location            = string
    # service_plan_id     = string ## using the data block

    # Storage wiring (one of the supported patterns)
    storage_account_name        = optional(string)
    rg_name_stg                 = optional(string)
    #    storage_account_access_key  = optional(string)   # conflicts with storage_uses_managed_identity # using the data block

    # App & platform
    functions_extension_version = optional(string)
    https_only                  = optional(bool)
    public_network_access_enabled = optional(bool, true)
    builtin_logging_enabled     = optional(bool, true)
    enabled                     = optional(bool, true)
    client_certificate_mode     = optional(string)
    vnet_image_pull_enabled     = optional(bool)
    ftp_publish_basic_authentication_enabled = optional(bool)
    webdeploy_publish_basic_authentication_enabled = optional(bool)
    tags                        = object({                                 # As it's Optional argument as per the terraform registry but we consider as required
      owner           = optional(string) # optional
      ApplicationName = string
      CreatedBy       = optional(string) #optional
      BusinessService = optional(string) #optional
      Environment     = string
      OpsTeam         = string
      Portfolio       = string
      PortfolioArea   = string
      RequestedBy     = string
      Vendor          = string
    })

    # Identity
    identity = optional(object({
      type         = string                      # "SystemAssigned" | "UserAssigned" | "SystemAssigned, UserAssigned"
      identity_ids = optional(list(string), [])  # required when using UserAssigned
    }))

    key_vault_reference_identity_id = optional(string) # for KV references via a user-assigned identity

    # App settings and connection strings
    app_settings = optional(map(string), {})
    connection_strings = optional(list(object({
      name  = string
      type  = string # one of APIHub, Custom, DocDb, EventHub, MySQL, NotificationHub, PostgreSQL, RedisCache, ServiceBus, SQLAzure, SQLServer
      value = string
    })), [])

    # Extra storage mounts (Azure Files)
    storage_accounts = optional(list(object({
      name        = string
      type        = string   # AzureFiles
      account_name = string
      access_key   = string
      share_name   = string
      mount_path   = optional(string)
    })), [])

    # Authentication (V1) — basic example
    auth_settings = optional(object({
      enabled                         = bool
      default_provider                = optional(string)
      issuer                          = optional(string)
      token_store_enabled             = optional(bool)
      token_refresh_extension_hours   = optional(number)
      unauthenticated_client_action   = optional(string)
      allowed_external_redirect_urls  = optional(list(string))
      additional_login_parameters     = optional(map(string))
      # (Extend with provider‑specific nested blocks if you need)
    }))

    # Authentication (V2) — commonly used flags
    auth_settings_v2 = optional(object({
      auth_enabled        = optional(bool, false)
      runtime_version     = optional(string, "~1")
      require_https       = optional(bool, true)
      require_authentication = optional(bool, false)
      unauthenticated_action = optional(string, "RedirectToLoginPage")

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
      # (You can add provider blocks if needed)
    }))

    # Site config (subset commonly used)
    site_config = optional(object({
      always_on        = optional(bool, false)
      http2_enabled    = optional(bool, false)
      minimum_tls_version = optional(string, "1.2")
      use_32_bit_worker   = optional(bool, true)
      ftps_state          = optional(string, "Disabled")
      health_check_path   = optional(string)
      pre_warmed_instance_count = optional(number)  # EP plan only
      app_scale_limit     = optional(number)        # Consumption/EP only
      worker_count        = optional(number)

      application_insights_connection_string = optional(string)
      application_insights_key               = optional(string)
      ip_restriction_default_action  = optional(string)  # Allow/Deny
      scm_ip_restriction_default_action = optional(string)
    }))
  }))
  validation {
    condition = alltrue(flatten([
      for w in values(var.windows_function_apps) : [
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
