#login variables used in the Terraform configuration
variable "subscription_id" {
  type = string
}
variable "client_id" {
  type = string
}
variable "client_secret" {
  type = string
}
variable "tenant_id" {
  type = string
}

# Resouce Group Variable 

variable "rg_name_mod" {

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
      for w in values(var.rg_name_mod) : [
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

# Storage Account Variable 

variable "storage_accounts_mod" {
  description = <<-EOT
  Map of Storage Account configurations. Keys are arbitrary IDs; values describe each storage account.

  Notes & Constraints (summarized from Azure/Terraform docs):
  - name: lowercase alphanumeric; must be globally unique; changing forces new resource.
  - account_tier: Standard | Premium. (BlockBlobStorage/FileStorage => Premium only)
  - account_kind: BlobStorage | BlockBlobStorage | FileStorage | Storage | StorageV2 (default StorageV2).
  - replication: LRS | GRS | RAGRS | ZRS | GZRS | RAGZRS; some changes force recreation.
  - access_tier: Hot | Cool | Cold | Premium; only valid for BlobStorage, FileStorage, StorageV2.
  - is_hns_enabled/NFS/SFTP compatibility rules apply (see Azure docs).
  - queue_properties allowed only on Standard with kind Storage/StorageV2.
  - static_website only on StorageV2/BlockBlobStorage.
  - share_properties: Standard (Storage/StorageV2) or Premium (FileStorage).
  - Customer-managed key requires StorageV2 or Premium + UserAssigned identity.
  EOT

  type = map(object({
    # ---------------- Core (Required) ----------------
    name                     = string # (Required)
    resource_group_name      = string # (Required)
    location                 = string # (Required)
    account_tier             = string # (Required) Standard | Premium
    account_replication_type = string # (Required) LRS | GRS | RAGRS | ZRS | GZRS | RAGZRS
    tags = object({                   # As it's Optional argument as per the terraform registry but we consider as required
      owner           = string        # optional
      ApplicationName = string
      CreatedBy       = optional(string) #optional
      BusinessService = optional(string) #optional
      Environment     = string
      OpsTeam         = string
      Portfolio       = string
      PortfolioArea   = string
      RequestedBy     = string
      Vendor          = string
      ServiceType     = optional(string) # This tag is used to specify the type of service. We make it optional here to avoid forcing all storage accounts to have it, but we ignore it in lifecycle to prevent unnecessary diffs if it's added/removed.
      SolutionName    = optional(string)
    })
    account_kind                    = optional(string)           # (Optional)
    is_hns_enabled                  = optional(bool, false)      # (Optional)
    nfsv3_enabled                   = optional(bool, false)      # (Optional)
    min_tls_version                 = optional(string, "TLS1_2") # (Optional) TLS1_0|TLS1_1|TLS1_2|TLS1_3
    public_network_access_enabled   = optional(bool, true)       # (Optional)
    allow_nested_items_to_be_public = optional(bool, true)       # (Optional)
    access_tier                     = optional(string)           # (Optional) Hot | Cool | Cold | Premium

    # ---------------- General (Optional) -------------

    provisioned_billing_model_version = optional(string)             # (Optional) e.g. "V2"
    cross_tenant_replication_enabled  = optional(bool, false)        # (Optional)
    edge_zone                         = optional(string)             # (Optional)
    https_traffic_only_enabled        = optional(bool, true)         # (Optional)
    shared_access_key_enabled         = optional(bool, true)         # (Optional)
    default_to_oauth_authentication   = optional(bool)               # (Optional)
    large_file_share_enabled          = optional(bool, false)        # (Optional)
    local_user_enabled                = optional(bool, true)         # (Optional)
    queue_encryption_key_type         = optional(string)             # (Optional) Service | Account
    table_encryption_key_type         = optional(string)             # (Optional) Service | Account
    infrastructure_encryption_enabled = optional(bool, false)        # (Optional)
    allowed_copy_scope                = optional(string)             # (Optional) AAD | PrivateLink
    sftp_enabled                      = optional(bool, false)        # (Optional; requires is_hns_enabled = true)
    dns_endpoint_type                 = optional(string, "Standard") # (Optional) Standard | AzureDnsZone
  }))

  # Condition to check wether the tags value is provided as per the policy
  validation {
    condition = alltrue(flatten([
      for w in values(var.storage_accounts_mod) : [
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

# Service Plan Variable

variable "service_plans_mod" {
  description = <<-EOT
    Map of App Service Plans to create. Keys are arbitrary plan keys.
    All resource arguments are supported; optional attributes can be omitted.
  EOT

  type = map(object({
    # Required
    name                = string
    location            = string
    resource_group_name = string
    os_type             = string # Windows | Linux | WindowsContainer
    sku_name            = string
    tags = object({                      # We are having azure policy that every resource will have the tags
      owner           = optional(string) # optional # Discussed with Adeel these are optional arguments
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
    # Optional
    app_service_environment_id      = optional(string) # Required if using Isolated v2 SKUs
    premium_plan_auto_scale_enabled = optional(bool)   # Premium SKUs only
    maximum_elastic_worker_count    = optional(number) # EP SKUs or Premium with auto-scale enabled
    worker_count                    = optional(number) # >= 1 for manual instance count
    per_site_scaling_enabled        = optional(bool)
    zone_balancing_enabled          = optional(bool)

    # Map of existing ASE v3 lookups. Key is an arbitrary label (ase_key) you’ll reference from service_plans.
    # To get the App Service Environment ID
    existing_ase_name = string
    existing_ase_rg   = string
  }))
  # Condition to check wether the tags value is provided as per the policy
  validation {
    condition = alltrue(flatten([
      for w in values(var.service_plans_mod) : [
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

# App Service Environment Variable

variable "app_service_environment_v3_mod" {
  description = "Map of ASEv3 definitions"
  type = map(object({
    name                                   = string
    resource_group_name                    = string
    subnet_id                              = string
    allow_new_private_endpoint_connections = optional(bool)
    internal_load_balancing_mode           = optional(string) # "None" or "Web, Publishing"
    remote_debugging_enabled               = optional(bool)
    dedicated_host_count                   = optional(number) # 2
    zone_redundant                         = optional(bool)
    cluster_settings = optional(list(object({
      name  = string
      value = string
    })))
    tags = object({
      # owner           = string # optional
      ApplicationName = string
      # CreatedBy       = string #optional
      BusinessService = string #optional
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
      for w in values(var.app_service_environment_v3_mod) : [
        # trimspace(w.tags.owner) != "",
        trimspace(w.tags.ApplicationName) != "",
        # trimspace(w.tags.CreatedBy) != "",
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

# Windows Function App

variable "windows_function_apps_mod" {
  description = "Map of Windows Function Apps to create"
  type = map(object({
    # data block to get the service plan ID
    existing_sp_name = string
    existing_sp_rg   = string
    # Requireds
    name                = string
    resource_group_name = string
    location            = string
    # service_plan_id     = string ## using the data block

    # Storage wiring (one of the supported patterns)
    storage_account_name = optional(string)
    rg_name_stg          = optional(string)
    #storage_account_access_key  = optional(string)   # conflicts with storage_uses_managed_identity ## using the data block

    # App & platform
    functions_extension_version                    = optional(string)
    https_only                                     = optional(bool)
    public_network_access_enabled                  = optional(bool, true)
    builtin_logging_enabled                        = optional(bool, true)
    enabled                                        = optional(bool, true)
    client_certificate_mode                        = optional(string)
    vnet_image_pull_enabled                        = optional(bool)
    ftp_publish_basic_authentication_enabled       = optional(bool)
    webdeploy_publish_basic_authentication_enabled = optional(bool)

    # Tags
    tags = object({                      # As it's Optional argument as per the terraform registry but we consider as required
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
      type         = string                     # "SystemAssigned" | "UserAssigned" | "SystemAssigned, UserAssigned"
      identity_ids = optional(list(string), []) # required when using UserAssigned
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
      name         = string
      type         = string # AzureFiles
      account_name = string
      access_key   = string
      share_name   = string
      mount_path   = optional(string)
    })), [])

    # Authentication (V1) — basic example
    auth_settings = optional(object({
      enabled                        = bool
      default_provider               = optional(string)
      issuer                         = optional(string)
      token_store_enabled            = optional(bool)
      token_refresh_extension_hours  = optional(number)
      unauthenticated_client_action  = optional(string)
      allowed_external_redirect_urls = optional(list(string))
      additional_login_parameters    = optional(map(string))
      # (Extend with provider‑specific nested blocks if you need)
    }))

    # Authentication (V2) — commonly used flags
    auth_settings_v2 = optional(object({
      auth_enabled           = optional(bool, false)
      runtime_version        = optional(string, "~1")
      require_https          = optional(bool, true)
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
      always_on                 = optional(bool, false)
      http2_enabled             = optional(bool, false)
      minimum_tls_version       = optional(string, "1.2")
      use_32_bit_worker         = optional(bool, true)
      ftps_state                = optional(string, "Disabled")
      health_check_path         = optional(string)
      pre_warmed_instance_count = optional(number) # EP plan only
      app_scale_limit           = optional(number) # Consumption/EP only
      worker_count              = optional(number)

      application_insights_connection_string = optional(string)
      application_insights_key               = optional(string)
      ip_restriction_default_action          = optional(string) # Allow/Deny
      scm_ip_restriction_default_action      = optional(string)
    }))
  }))
  validation {
    condition = alltrue(flatten([
      for w in values(var.windows_function_apps_mod) : [
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

# Windows Function App Slot
# Not Required as this variable value is taken from Output Block 
# windows_function_ids       = module.windows_function_app.function_app_ids
# variable "windows_function_ids" {
#   type = map(string)
# }
variable "windows_function_app_slots_mod" {
  description = "Map of Windows Function App Slots to create (provider v4+)."
  type = map(object({
    # -------- Required --------
    name = string
    # function_app_id = string # using the data block
    # -----------Data Block----------
    #To get the Function App 
    existing_func_app_name = string
    existing_func_app_rg   = string
    # function_app_id = string

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

    # -------- Optional top-level arguments --------
    service_plan_id = optional(string)
    app_settings    = optional(map(string))

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
      unauthenticated_client_action  = optional(string) # RedirectToLoginPage | AllowAnonymous
    }))

    auth_settings_v2 = optional(object({
      auth_enabled                            = optional(bool)
      runtime_version                         = optional(string) # defaults to ~1 in resource
      config_file_path                        = optional(string)
      require_authentication                  = optional(bool)
      unauthenticated_action                  = optional(string) # RedirectToLoginPage | AllowAnonymous | Return401 | Return403
      default_provider                        = optional(string) # apple | azureactivedirectory | facebook | github | google | twitter | <custom oidc name>
      excluded_paths                          = optional(list(string))
      require_https                           = optional(bool)
      http_route_api_prefix                   = optional(string)
      forward_proxy_convention                = optional(string) # NoProxy | Standard | Custom
      forward_proxy_custom_host_header_name   = optional(string)
      forward_proxy_custom_scheme_header_name = optional(string)

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
        logout_endpoint                   = optional(string)
        token_store_enabled               = optional(bool)
        token_refresh_extension_time      = optional(number)
        token_store_path                  = optional(string)
        token_store_sas_setting_name      = optional(string)
        preserve_url_fragments_for_logins = optional(bool)
        allowed_external_redirect_urls    = optional(list(string))
        cookie_expiration_convention      = optional(string)
        cookie_expiration_time            = optional(string) # HH:MM:SS
        validate_nonce                    = optional(bool)
        nonce_expiration_time             = optional(string) # HH:MM:SS
      })
    }))

    builtin_logging_enabled    = optional(bool)
    client_certificate_mode    = optional(string)
    client_certificate_enabled = optional(bool)
    connection_strings = optional(list(object({
      name  = string
      type  = string
      value = string
    })))
    daily_memory_time_quota                        = optional(number)
    enabled                                        = optional(bool)
    functions_extension_version                    = optional(string)
    https_only                                     = optional(bool)
    public_network_access_enabled                  = optional(bool)
    ftp_publish_basic_authentication_enabled       = optional(bool)
    webdeploy_publish_basic_authentication_enabled = optional(bool)

    identity = optional(object({
      type         = string # SystemAssigned | UserAssigned | SystemAssigned, UserAssigned
      identity_ids = optional(list(string))
    }))

    # Storage mounting (Azure Files)
    storage_accounts = optional(list(object({
      name         = string
      type         = string # AzureFiles
      account_name = string
      access_key   = string
      share_name   = string
      mount_path   = optional(string)
    })))

    storage_account_name = optional(string)
    rg_name_stg          = optional(string)
    # storage_account_access_key      = optional(string)  # conflict with storage_uses_managed_identity
    virtual_network_backup_restore_enabled = optional(bool)
    virtual_network_subnet_id              = optional(string) # cannot be used with separate swift_connection for same app/slot
    vnet_image_pull_enabled                = optional(bool)

    tags = object({                      # We are having azure policy that every resource will have the tags
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
  }))
  validation {
    condition = alltrue(flatten([
      for w in values(var.windows_function_app_slots_mod) : [
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

# # Linux Function App

variable "linux_function_apps_mod" {
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
    functions_extension_version                    = optional(string)
    https_only                                     = optional(bool)
    public_network_access_enabled                  = optional(bool, true)
    enabled                                        = optional(bool, true)
    builtin_logging_enabled                        = optional(bool)
    ftp_publish_basic_authentication_enabled       = optional(bool)
    webdeploy_publish_basic_authentication_enabled = optional(bool)
    vnet_image_pull_enabled                        = optional(bool)
    client_certificate_enabled                     = optional(bool)
    client_certificate_mode                        = optional(string) # Required 


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
      type         = string # SystemAssigned | UserAssigned | Both
      identity_ids = optional(list(string), [])
    }))

    key_vault_reference_identity_id = optional(string)

    # -------- App settings --------
    app_settings = optional(map(string), {})

    # -------- Site Config (Linux specific) --------
    # site_config = optional(object({
    #   always_on           = optional(bool, false)
    #   http2_enabled       = optional(bool, false)
    #   minimum_tls_version = optional(string, "1.2")

    #   # ---- Linux runtime stack (IMPORTANT difference) ----
    #   application_stack = optional(object({
    #     dotnet_version = optional(string)
    #     node_version   = optional(string)
    #     python_version = optional(string)
    #     java_version   = optional(string)
    #     })
    #   )

    #   application_insights_connection_string = optional(string)
    #   application_insights_key               = optional(string)

    #   ip_restriction_default_action     = optional(string)
    #   scm_ip_restriction_default_action = optional(string)
    # }))
    site_config = optional(object({
      always_on                              = optional(bool)
      http2_enabled                          = optional(bool)
      minimum_tls_version                    = optional(string)
      use_32_bit_worker                      = optional(bool)
      ftps_state                             = optional(string)
      health_check_path                      = optional(string)
      worker_count                           = optional(number)
      application_insights_connection_string = optional(string)
      application_insights_key               = optional(string)
      ip_restriction_default_action          = optional(string)
      scm_ip_restriction_default_action      = optional(string)

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
      enabled                        = bool
      default_provider               = optional(string)
      issuer                         = optional(string)
      token_store_enabled            = optional(bool)
      token_refresh_extension_hours  = optional(number)
      unauthenticated_client_action  = optional(string)
      allowed_external_redirect_urls = optional(list(string))
      additional_login_parameters    = optional(map(string))
    }))

    # -------- Authentication (v2) --------
    auth_settings_v2 = optional(object({
      auth_enabled           = optional(bool, false)
      runtime_version        = optional(string, "~1")
      require_https          = optional(bool, true)
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
    }))
  }))

  # ------------------------------------------------------------
  # Validation (same rule as Windows)
  # ------------------------------------------------------------
  validation {
    condition = alltrue(flatten([
      for l in values(var.linux_function_apps_mod) : [
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

# Linux Function App Slot
# Not Required as this variable value is taken from Output Block 
# variable "linux_function_ids" {
#   type = map(string)
# }

variable "linux_function_app_slots_mod" {
  description = "Map of Linux Function App Slots"
  type = map(object({

    # -------- Required --------
    name                   = string
    existing_func_app_name = string
    existing_func_app_rg   = string

    # Required block (fields inside are optional)
    site_config = optional(object({
      always_on                 = optional(bool, false)
      http2_enabled             = optional(bool, false)
      minimum_tls_version       = optional(string, "1.2")
      use_32_bit_worker         = optional(bool, true)
      ftps_state                = optional(string, "Disabled")
      health_check_path         = optional(string)
      pre_warmed_instance_count = optional(number) # EP plan only
      app_scale_limit           = optional(number) # Consumption/EP only
      worker_count              = optional(number)

      application_insights_connection_string = optional(string)
      application_insights_key               = optional(string)
      ip_restriction_default_action          = optional(string) # Allow/Deny
      scm_ip_restriction_default_action      = optional(string)
    }))

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
      for s in values(var.linux_function_app_slots_mod) : [
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

# Windows Web Apps
# ------------------------------------------------------------
variable "windows_web_apps_mod" {
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
    client_certificate_mode                        = optional(string) # Required | Optional | OptionalInteractiveUser
    client_certificate_enabled                     = optional(bool)
    builtin_logging_enabled                        = optional(bool)
    ftp_publish_basic_authentication_enabled       = optional(bool)
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
      type         = string # SystemAssigned | UserAssigned | Both
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
      auth_enabled           = optional(bool, false)
      runtime_version        = optional(string, "~1")
      require_https          = optional(bool, true)
      require_authentication = optional(bool, false)
      unauthenticated_action = optional(string, "RedirectToLoginPage")

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
      websockets_enabled  = optional(bool)
      health_check_path   = optional(string)
      worker_count        = optional(number)
      #  app_scale_limit     = optional(number)        # Not present in this block Consumption/EP only

      # application_insights_connection_string = optional(string) # Not present in this block
      # application_insights_key               = optional(string) # Not present in this block
      ip_restriction_default_action     = optional(string) # Allow/Deny
      scm_ip_restriction_default_action = optional(string)
    }))
  }))

  # ------------------------------------------------------------
  # Validation – same as all resources to ensure mandatory tags are populated
  # ------------------------------------------------------------
  validation {
    condition = alltrue(flatten([
      for w in values(var.windows_web_apps_mod) : [
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

# # Windows Web App Slot
# # Not Required as this variable value is taken from Output Block 
# # variable "windows_web_app_ids" {
# #   type = map(string)
# # }

variable "windows_web_app_slots_mod" {
  description = "Map of Windows Web App Slots"
  type = map(object({

    # -------- Required --------
    name                  = string
    existing_web_app_name = string

    # -------- Optional overrides --------
    service_plan_id = optional(string)

    enabled                                        = optional(bool)
    https_only                                     = optional(bool)
    public_network_access_enabled                  = optional(bool)
    client_affinity_enabled                        = optional(bool)
    client_certificate_mode                        = optional(string) # Required | Optional | OptionalInteractiveUser
    client_certificate_enabled                     = optional(bool)
    builtin_logging_enabled                        = optional(bool)
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
      identity_ids = optional(list(string))
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

    sticky_settings = optional(object({
      app_setting_names       = optional(list(string))
      connection_string_names = optional(list(string))
    }))

    site_config = optional(object({
      always_on                              = optional(bool)
      http2_enabled                          = optional(bool)
      minimum_tls_version                    = optional(string)
      use_32_bit_worker                      = optional(bool)
      ftps_state                             = optional(string)
      health_check_path                      = optional(string)
      worker_count                           = optional(number)
      application_insights_connection_string = optional(string)
      application_insights_key               = optional(string)

      # Not part of Windows Web App Slots
      #pre_warmed_instance_count = optional(number) 
      #app_scale_limit     = optional(number)
      #ip_restriction_default_action     = optional(string)
      #scm_ip_restriction_default_action = optional(string)

    }))

    # site_config = object({
    #   always_on           = optional(bool)
    #   http2_enabled       = optional(bool)
    #   minimum_tls_version = optional(string)
    #   ftps_state          = optional(string)
    #   use_32_bit_worker   = optional(bool)
    #   websockets_enabled = optional(bool)
    #   health_check_path  = optional(string)
    #   worker_count       = optional(number)

    #   application_stack = optional(object({
    #     current_stack       = optional(string)
    #     dotnet_version      = optional(string)
    #     dotnet_core_version = optional(string)
    #     node_version        = optional(string)
    #     java_version        = optional(string)
    #     php_version         = optional(string)
    #     python              = optional(bool)
    #   }))

    #   cors = optional(object({
    #     allowed_origins     = list(string)
    #     support_credentials = optional(bool)
    #   }))
    # })

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
      for s in values(var.windows_web_app_slots_mod) : [
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

# Linux Web Apps
# ------------------------------------------------------------
variable "linux_web_apps_mod" {
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
    client_certificate_enabled    = optional(bool)
    client_certificate_mode       = optional(string)

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
      auth_enabled           = optional(bool, false)
      runtime_version        = optional(string, "~1")
      require_https          = optional(bool, true)
      require_authentication = optional(bool, false)
      unauthenticated_action = optional(string)

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
      for s in values(var.linux_web_apps_mod) : [
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

# Linux Web Apps Slots

variable "linux_web_app_slots_mod" {
  description = "Map of Linux Web App Slots"
  type = map(object({
    name                        = string
    existing_linux_web_app_name = string # reference key of parent linux web app

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
    })), [])

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
      for s in values(var.linux_web_app_slots_mod) : [
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


# Key Vault

variable "key_vaults_mod" {

  type = map(object({

    name                = string
    location            = string
    resource_group_name = string

    # tenant_id = string

    sku_name = string

    # Core Features
    enabled_for_deployment          = optional(bool)
    enabled_for_disk_encryption     = optional(bool)
    enabled_for_template_deployment = optional(bool)

    rbac_authorization_enabled    = optional(bool, false)
    public_network_access_enabled = optional(bool, false)

    purge_protection_enabled = optional(bool, false)

    soft_delete_retention_days = optional(number, 90)

    # Network
    network_acls = optional(object({

      bypass         = string
      default_action = string

      ip_rules = optional(list(string), [])

      virtual_network_subnet_ids = optional(list(string), [])

    }))

    # Access Policies
    access_policies = optional(list(object({

      tenant_id = string
      object_id = string

      #   application_id = optional(string)

      key_permissions = optional(list(string), [])

      secret_permissions = optional(list(string), [])

      certificate_permissions = optional(list(string), [])

      storage_permissions = optional(list(string), [])

    })), [])

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

  # ------------------------------------------------------------
  # Validation (same rule as Windows)
  # ------------------------------------------------------------
  validation {
    condition = alltrue(flatten([
      for l in values(var.key_vaults_mod) : [
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
    error_message = "Each Key vaults must include non-empty tag values for all mandatory tags."
  }
}

# Kubernetes Cluster 

# variable "kubernetes_clusters_mod" {
#   description = "Map of AKS clusters"

#   type = map(object({
#     name                = string
#     location            = string
#     resource_group_name = string

#     dns_prefix                 = optional(string)
#     dns_prefix_private_cluster = optional(string)

#     kubernetes_version        = optional(string)
#     automatic_upgrade_channel = optional(string)
#     node_os_upgrade_channel   = optional(string)

#     sku_tier     = optional(string)
#     support_plan = optional(string)

#     node_resource_group                 = optional(string)
#     private_cluster_enabled             = optional(bool)
#     private_dns_zone_id                 = optional(string)
#     private_cluster_public_fqdn_enabled = optional(bool)

#     role_based_access_control_enabled = optional(bool)
#     local_account_disabled            = optional(bool)

#     azure_policy_enabled       = optional(bool)
#     oidc_issuer_enabled        = optional(bool)
#     workload_identity_enabled  = optional(bool)
#     run_command_enabled        = optional(bool)
#     image_cleaner_enabled      = optional(bool)
#     image_cleaner_interval_hours = optional(number)
#     cost_analysis_enabled      = optional(bool)

#     default_node_pool = object({
#       name    = string
#       vm_size = optional(string)

#       node_count           = optional(number)
#       auto_scaling_enabled = optional(bool)
#       min_count            = optional(number)
#       max_count            = optional(number)

#       vnet_subnet_id = optional(string)
#       pod_subnet_id  = optional(string)

#       zones       = optional(list(string))
#       node_labels = optional(map(string), {})

#       max_pods = optional(number)

#       os_disk_size_gb = optional(number)
#       os_disk_type    = optional(string)
#       os_sku          = optional(string)

#       host_encryption_enabled      = optional(bool)
#       node_public_ip_enabled       = optional(bool)
#       only_critical_addons_enabled = optional(bool)

#       temporary_name_for_rotation = optional(string)

#       upgrade_settings = optional(object({
#         max_surge                     = string
#         drain_timeout_in_minutes      = optional(number)
#         node_soak_duration_in_minutes = optional(number)
#         undrainable_node_behavior     = optional(string)
#       }))
#     })

#     identity = optional(object({
#       type         = string
#       identity_ids = optional(list(string), [])
#     }))

#     service_principal = optional(object({
#       client_id     = string
#       client_secret = string
#     }))

#     network_profile = optional(object({
#       network_plugin      = string
#       network_plugin_mode = optional(string)
#       network_policy      = optional(string)
#       network_data_plane  = optional(string)

#       dns_service_ip = optional(string)

#       pod_cidr  = optional(string)
#       pod_cidrs = optional(list(string))

#       service_cidr  = optional(string)
#       service_cidrs = optional(list(string))

#       ip_versions       = optional(list(string))
#       outbound_type     = optional(string)
#       load_balancer_sku = optional(string)

#       load_balancer_profile = optional(object({
#         backend_pool_type           = optional(string)
#         idle_timeout_in_minutes     = optional(number)
#         managed_outbound_ip_count   = optional(number)
#         managed_outbound_ipv6_count = optional(number)
#         outbound_ip_address_ids     = optional(list(string))
#         outbound_ip_prefix_ids      = optional(list(string))
#         outbound_ports_allocated    = optional(number)
#       }))

#       nat_gateway_profile = optional(object({
#         idle_timeout_in_minutes   = optional(number)
#         managed_outbound_ip_count = optional(number)
#       }))
#     }))

#     api_server_access_profile = optional(object({
#       authorized_ip_ranges                = optional(set(string), [])
#       subnet_id                           = optional(string)
#       virtual_network_integration_enabled = optional(bool)
#     }))

#     azure_active_directory_role_based_access_control = optional(object({
#       tenant_id              = optional(string)
#       admin_group_object_ids = optional(list(string), [])
#       azure_rbac_enabled     = optional(bool)
#     }))

#     key_vault_secrets_provider = optional(object({
#       secret_rotation_enabled  = optional(bool)
#       secret_rotation_interval = optional(string)
#     }))

#     monitor_metrics = optional(object({
#       annotations_allowed = optional(string)
#       labels_allowed      = optional(string)
#     }))

#     auto_scaler_profile = optional(object({
#       balance_similar_node_groups      = optional(bool)
#       expander                         = optional(string)
#       max_graceful_termination_sec     = optional(string)
#       max_node_provisioning_time       = optional(string)
#       max_unready_nodes                = optional(number)
#       max_unready_percentage           = optional(number)
#       new_pod_scale_up_delay           = optional(string)
#       scale_down_delay_after_add       = optional(string)
#       scale_down_delay_after_delete    = optional(string)
#       scale_down_delay_after_failure   = optional(string)
#       scan_interval                    = optional(string)
#       scale_down_unneeded              = optional(string)
#       scale_down_unready               = optional(string)
#       scale_down_utilization_threshold = optional(string)
#       empty_bulk_delete_max            = optional(string)
#       skip_nodes_with_local_storage    = optional(bool)
#       skip_nodes_with_system_pods      = optional(bool)
#     }))

#     workload_autoscaler_profile = optional(object({
#       keda_enabled                    = optional(bool)
#       vertical_pod_autoscaler_enabled = optional(bool)
#     }))

#     storage_profile = optional(object({
#       blob_driver_enabled         = optional(bool)
#       disk_driver_enabled         = optional(bool)
#       file_driver_enabled         = optional(bool)
#       snapshot_controller_enabled = optional(bool)
#     }))

#     linux_profile = optional(object({
#       admin_username = string

#       ssh_key = object({
#         key_data = string
#       })
#     }))

#     tags = object({
#       owner           = string
#       ApplicationName = string
#       CreatedBy       = string
#       BusinessService = string
#       Environment     = string
#       OpsTeam         = string
#       Portfolio       = string
#       PortfolioArea   = string
#       RequestedBy     = string
#       Vendor          = string
#     })
#   }))

#   # ------------------------------------------------------------
#   # Validation (same rule as Windows)
#   # ------------------------------------------------------------
#   validation {
#     condition = alltrue(flatten([
#       for l in values(var.kubernetes_clusters_mod) : [
#         trimspace(l.tags.owner) != "",
#         trimspace(l.tags.ApplicationName) != "",
#         trimspace(l.tags.CreatedBy) != "",
#         trimspace(l.tags.BusinessService) != "",
#         trimspace(l.tags.Environment) != "",
#         trimspace(l.tags.OpsTeam) != "",
#         trimspace(l.tags.Portfolio) != "",
#         trimspace(l.tags.PortfolioArea) != "",
#         trimspace(l.tags.RequestedBy) != "",
#         trimspace(l.tags.Vendor) != ""
#       ]
#     ]))
#     error_message = "Each Kubernetes Cluster must include non-empty tag values for all mandatory tags."
#   }
# }

# ------------------------------------------------------------
# Kubernetes Cluster Node Pools
# ------------------------------------------------------------

# variable "kubernetes_node_pools_mod" {
#   description = "Map of additional AKS Node Pools"

#   type = map(object({

#     # Reference key
#     existing_aks_name = string

#     # Required
#     name    = string
#     vm_size = string

#     # Node sizing
#     node_count = optional(number)

#     mode = optional(string, "User")

#     auto_scaling_enabled = optional(bool)
#     min_count            = optional(number)
#     max_count            = optional(number)

#     max_pods = optional(number)

#     orchestrator_version = optional(string)

#     # Networking
#     vnet_subnet_id = optional(string)
#     pod_subnet_id  = optional(string)

#     zones = optional(list(string), [])

#     # Node metadata
#     node_labels = optional(map(string), {})
#     node_taints = optional(list(string), [])

#     # Security
#     host_encryption_enabled = optional(bool)
#     node_public_ip_enabled  = optional(bool)
#     node_public_ip_prefix_id = optional(string)
#     fips_enabled             = optional(bool)
#     ultra_ssd_enabled        = optional(bool)

#     # OS
#     os_type = optional(string, "Linux")
#     os_sku  = optional(string)

#     os_disk_size_gb = optional(number)
#     os_disk_type    = optional(string)

#     kubelet_disk_type = optional(string)

#     temporary_name_for_rotation = optional(string)

#     # Upgrade
#     upgrade_settings = optional(object({
#       max_surge                     = string
#       drain_timeout_in_minutes      = optional(number)
#       node_soak_duration_in_minutes = optional(number)
#       undrainable_node_behavior     = optional(string)
#     }))

#     # Kubelet
#     kubelet_config = optional(object({
#       allowed_unsafe_sysctls    = optional(list(string), [])
#       container_log_max_files   = optional(number)
#       container_log_max_size_mb = optional(number)
#       cpu_cfs_quota_enabled     = optional(bool)
#       cpu_cfs_quota_period      = optional(string)
#       cpu_manager_policy        = optional(string)
#       image_gc_high_threshold   = optional(number)
#       image_gc_low_threshold    = optional(number)
#       pod_max_pid               = optional(number)
#       topology_manager_policy   = optional(string)
#     }))

#     linux_os_config = optional(object({
#       swap_file_size_mb            = optional(number)
#       transparent_huge_page        = optional(string)
#       transparent_huge_page_defrag = optional(string)

#       sysctl_config = optional(object({
#         fs_aio_max_nr               = optional(number)
#         fs_file_max                 = optional(number)
#         fs_inotify_max_user_watches = optional(number)
#         fs_nr_open                  = optional(number)

#         net_core_netdev_max_backlog = optional(number)
#         net_core_rmem_max           = optional(number)
#         net_core_somaxconn          = optional(number)
#         net_core_wmem_max           = optional(number)

#         net_ipv4_tcp_fin_timeout      = optional(number)
#         net_ipv4_tcp_keepalive_intvl  = optional(number)
#         net_ipv4_tcp_keepalive_probes = optional(number)
#         net_ipv4_tcp_keepalive_time   = optional(number)
#         net_ipv4_tcp_max_syn_backlog  = optional(number)

#         vm_max_map_count      = optional(number)
#         vm_swappiness         = optional(number)
#         vm_vfs_cache_pressure = optional(number)
#       }))
#     }))

#     tags = object({
#       owner           = string
#       ApplicationName = string
#       CreatedBy       = string
#       BusinessService = string
#       Environment     = string
#       OpsTeam         = string
#       Portfolio       = string
#       PortfolioArea   = string
#       RequestedBy     = string
#       Vendor          = string
#     })
#   }))

#   # ------------------------------------------------------------
#   # Validation (same rule as Kubernetes Cluster)
#   # ------------------------------------------------------------
#   validation {
#     condition = alltrue(flatten([
#       for l in values(var.kubernetes_node_pools_mod) : [
#         trimspace(l.tags.owner) != "",
#         trimspace(l.tags.ApplicationName) != "",
#         trimspace(l.tags.CreatedBy) != "",
#         trimspace(l.tags.BusinessService) != "",
#         trimspace(l.tags.Environment) != "",
#         trimspace(l.tags.OpsTeam) != "",
#         trimspace(l.tags.Portfolio) != "",
#         trimspace(l.tags.PortfolioArea) != "",
#         trimspace(l.tags.RequestedBy) != "",
#         trimspace(l.tags.Vendor) != ""
#       ]
#     ]))
#     error_message = "Each Kubernetes Cluster must include non-empty tag values for all mandatory tags."
#   }
# }


# NIC Configuration

variable "network_interfaces_mod" {

  type = map(object({

    name                = string
    resource_group_name = string
    location            = string
    accelerated_networking_enabled = optional(bool)
    ip_configurations = list(object({

      name                          = string
      subnet_id                     = string
      private_ip_address_allocation = string

      private_ip_address = optional(string)
      public_ip_address_id = optional(string)

      primary = optional(bool)
    }))

    tags = map(string)
  }))
}

# Windows Virtual Machines Configuration
# variable "windows_virtual_machines_mod" {

#   description = "Map of Windows Virtual Machines"

#   type = map(object({

#     name                = string
#     resource_group_name = string
#     location            = string

#     size = string

#     existing_nic_names  = list(string)  # this value we need to share from the existing NICs

#     admin_username = optional(string)
#     admin_password = optional(string)

#     computer_name = optional(string)

#     availability_set_id           = optional(string)
#     capacity_reservation_group_id = optional(string)

#     proximity_placement_group_id = optional(string)

#     allow_extension_operations = optional(bool,true)

#     provision_vm_agent = optional(bool,true)

#     automatic_updates_enabled = optional(bool,true)

#     patch_mode            = optional(string)
#     patch_assessment_mode = optional(string)

#     encryption_at_host_enabled = optional(bool)

#     secure_boot_enabled = optional(bool)
#     vtpm_enabled        = optional(bool)

#     source_image_id    = optional(string)
#     os_managed_disk_id = optional(string)

#     custom_data = optional(string)
#     user_data   = optional(string)

#     timezone = optional(string)
#     zone     = optional(string)

#     priority        = optional(string)
#     eviction_policy = optional(string)
#     max_bid_price   = optional(number)

#     license_type = optional(string)

#     os_disk = object({

#       caching = string

#       storage_account_type = optional(string)

#       disk_size_gb = optional(number)

#       name = optional(string)

#       disk_encryption_set_id = optional(string)

#       secure_vm_disk_encryption_set_id = optional(string)

#       security_encryption_type = optional(string)

#       write_accelerator_enabled = optional(bool)

#       diff_disk_settings = optional(object({

#         option    = string
#         placement = optional(string)

#       }))
#     })

#     source_image_reference = optional(object({

#       publisher = string
#       offer     = string
#       sku       = string
#       version   = string

#     }))

#     identity = optional(object({

#       type = string

#       identity_ids = optional(list(string))

#     }))

#     additional_capabilities = optional(object({

#       ultra_ssd_enabled   = optional(bool)
#       hibernation_enabled = optional(bool)

#     }))

#     boot_diagnostics = optional(object({

#       storage_account_uri = optional(string)

#     }))

#     plan = optional(object({

#       name      = string
#       publisher = string
#       product   = string

#     }))

#     tags = object({
#       owner           = optional(string) # optional
#       ApplicationName = string
#       CreatedBy       = optional(string) # optional
#       BusinessService = optional(string) # optional
#       Environment     = string
#       OpsTeam         = string
#       Portfolio       = string
#       PortfolioArea   = string
#       RequestedBy     = string
#       Vendor          = string
#     })
#   }))
#  # ------------------------------------------------------------
#   # Validation – same as all resources to ensure mandatory tags are populated
#   # ------------------------------------------------------------
#   validation {
#     condition = alltrue(flatten([
#       for w in values(var.windows_virtual_machines_mod) : [
#         # trimspace(w.tags.owner) != "",
#         trimspace(w.tags.ApplicationName) != "",
#         # trimspace(w.tags.CreatedBy) != "",
#         # trimspace(w.tags.BusinessService) != "",
#         trimspace(w.tags.Environment) != "",
#         trimspace(w.tags.OpsTeam) != "",
#         trimspace(w.tags.Portfolio) != "",
#         trimspace(w.tags.PortfolioArea) != "",
#         trimspace(w.tags.RequestedBy) != "",
#         trimspace(w.tags.Vendor) != ""
#       ]
#     ]))
#     error_message = "Each Windows Virtual Machine must include non-empty values for all mandatory tags."
#   }
# }

# Linux Virtual Machines 
variable "linux_virtual_machines_mod" {

  description = "Map of Linux Virtual Machines"

  type = map(object({

    name                = string
    resource_group_name = string
    location            = string

    size = string

    existing_nic_names  = list(string)  # this value we need to share from the existing NICs

    admin_username = optional(string)
    admin_password = optional(string)

    computer_name = optional(string)

    availability_set_id           = optional(string)
    capacity_reservation_group_id = optional(string)

    proximity_placement_group_id = optional(string)

    allow_extension_operations = optional(bool,true)

    provision_vm_agent = optional(bool,true)
    
    reboot_setting = optional(string, "Never")

    automatic_updates_enabled = optional(bool,true)

    patch_mode            = optional(string)
    patch_assessment_mode = optional(string)

    encryption_at_host_enabled = optional(bool)

    secure_boot_enabled = optional(bool, true)
    vtpm_enabled        = optional(bool, true)

    source_image_id    = optional(string)
    os_managed_disk_id = optional(string)

    custom_data = optional(string)
    user_data   = optional(string)

    timezone = optional(string)
    zone     = optional(string)
    disable_password_authentication = optional(bool, false)
    priority        = optional(string)
    eviction_policy = optional(string)
    max_bid_price   = optional(number)

    license_type = optional(string)

    os_disk = object({

      caching = string

      storage_account_type = optional(string)

      disk_size_gb = optional(number)

      name = optional(string)

      disk_encryption_set_id = optional(string)

      secure_vm_disk_encryption_set_id = optional(string)

      security_encryption_type = optional(string)

      write_accelerator_enabled = optional(bool)

      diff_disk_settings = optional(object({

        option    = string
        placement = optional(string)

      }))
    })

    source_image_reference = optional(object({

      publisher = string
      offer     = string
      sku       = string
      version   = string

    }))

    identity = optional(object({

      type = string

      identity_ids = optional(list(string))

    }))

    additional_capabilities = optional(object({

      ultra_ssd_enabled   = optional(bool)
      hibernation_enabled = optional(bool)

    }))

    boot_diagnostics = optional(object({

      storage_account_uri = optional(string)

    }))

    plan = optional(object({

      name      = string
      publisher = string
      product   = string

    }))

    admin_ssh_keys = optional(list(object({

    username   = string
    public_key = string

    })), [])

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
      LegacyVMNVA      = optional(string) # optional
      MonthlyServerMaintenance = optional(string) # optional
      MonthlyServerMaintenanceExclusionReason = optional(string) # optional
    })
  }))
  # ------------------------------------------------------------
  # Validation – same as all resources to ensure mandatory tags are populated
  # ------------------------------------------------------------
  validation {
    condition = alltrue(flatten([
      for w in values(var.linux_virtual_machines_mod) : [
        # trimspace(w.tags.owner) != "",
        trimspace(w.tags.ApplicationName) != "",
        # trimspace(w.tags.CreatedBy) != "",
        # trimspace(w.tags.BusinessService) != "",
        trimspace(w.tags.Environment) != "",
        # trimspace(w.tags.LegacyVMNVA) != "",
        # trimspace(w.tags.MonthlyServerMaintenance) != "",
        # trimspace(w.tags.MonthlyServerMaintenanceExclusionReason) != "",
        trimspace(w.tags.OpsTeam) != "",
        trimspace(w.tags.Portfolio) != "",
        trimspace(w.tags.PortfolioArea) != "",
        trimspace(w.tags.RequestedBy) != "",
        trimspace(w.tags.Vendor) != ""
      ]
    ]))
    error_message = "Each Linux Virtual Machine must include non-empty values for all mandatory tags."
  }
}

