# data "azurerm_windows_function_app" "function_apps" {
#   for_each = var.windows_function_app_slots
#   name                = each.value.existing_func_app_name
#   resource_group_name = each.value.existing_func_app_rg
# }

data "azurerm_storage_account" "storage_accounts" {
  for_each = var.windows_function_app_slots
  name                = each.value.storage_account_name
  resource_group_name = each.value.rg_name_stg
}


resource "azurerm_windows_function_app_slot" "windows_function_app_slots" {
  for_each = var.windows_function_app_slots

  name            = each.value.name
  function_app_id = var.windows_function_ids[each.value.existing_func_app_name]
  # Using the Output Block for getting the function_app_id 
  # function_app_id = data.azurerm_windows_function_app.function_apps[each.key].id
  # function_app_id = one(
  #   [
  #     for id in values(var.windows_function_ids) :
  #     id
  #     if each.value.existing_func_app_name == split("/", id)[length(split("/", id)) - 1]
  #   ]
  # )

  # Optional: override plan for the slot
  service_plan_id = lookup(each.value, "service_plan_id", null)

  # ----- Storage identity/key/key-vault -----
  storage_account_name          = lookup(each.value, "storage_account_name", null)
  storage_account_access_key    = data.azurerm_storage_account.storage_accounts[each.key].primary_access_key   
  # storage_account_access_key    = lookup(each.value, "storage_account_access_key", null)

  # ----- Core toggles -----
  app_settings                           = lookup(each.value, "app_settings", null)
  builtin_logging_enabled                = lookup(each.value, "builtin_logging_enabled", null)
  client_certificate_enabled             = lookup(each.value, "client_certificate_enabled", null)
  client_certificate_mode                = lookup(each.value, "client_certificate_mode", null)
  daily_memory_time_quota                = lookup(each.value, "daily_memory_time_quota", null)
  enabled                                = lookup(each.value, "enabled", null)
  functions_extension_version            = lookup(each.value, "functions_extension_version", null)
  https_only                             = lookup(each.value, "https_only", null)
  public_network_access_enabled          = lookup(each.value, "public_network_access_enabled", null)
  tags                                   = each.value.tags
  virtual_network_backup_restore_enabled = lookup(each.value, "virtual_network_backup_restore_enabled", null)
  virtual_network_subnet_id              = lookup(each.value, "virtual_network_subnet_id", null)
  vnet_image_pull_enabled                = lookup(each.value, "vnet_image_pull_enabled", null)
  ftp_publish_basic_authentication_enabled      = lookup(each.value, "ftp_publish_basic_authentication_enabled", null)
  webdeploy_publish_basic_authentication_enabled = lookup(each.value, "webdeploy_publish_basic_authentication_enabled", null)
  
  # Identity
  dynamic "identity" {
    for_each = lookup(each.value, "identity", null) != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = lookup(identity.value, "identity_ids", null)
    }
  }

  # Connection strings
  dynamic "connection_string" {
    for_each = each.value.connection_strings != null ? each.value.connection_strings : []
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  # Storage mounts (Azure Files)
  dynamic "storage_account" {
    for_each = each.value.storage_accounts != null ? each.value.storage_accounts : []
    content {
      name         = storage_account.value.name
      type         = storage_account.value.type
      account_name = storage_account.value.account_name
      access_key   = storage_account.value.access_key
      share_name   = storage_account.value.share_name
      mount_path   = lookup(storage_account.value, "mount_path", null)
    }
  }

  # Auth v1
  dynamic "auth_settings" {
    for_each = lookup(each.value, "auth_settings", null) != null ? [each.value.auth_settings] : []
    content {
      enabled                       = auth_settings.value.enabled
      additional_login_parameters    = lookup(auth_settings.value, "additional_login_parameters", null)
      allowed_external_redirect_urls = lookup(auth_settings.value, "allowed_external_redirect_urls", null)
      default_provider               = lookup(auth_settings.value, "default_provider", null)
      issuer                         = lookup(auth_settings.value, "issuer", null)
      runtime_version                = lookup(auth_settings.value, "runtime_version", null)
      token_refresh_extension_hours  = lookup(auth_settings.value, "token_refresh_extension_hours", null)
      token_store_enabled            = lookup(auth_settings.value, "token_store_enabled", null)
      unauthenticated_client_action  = lookup(auth_settings.value, "unauthenticated_client_action", null)

      dynamic "active_directory" {
        for_each = lookup(auth_settings.value, "active_directory", null) != null ? [auth_settings.value.active_directory] : []
        content {
          client_id                  = active_directory.value.client_id
          allowed_audiences          = lookup(active_directory.value, "allowed_audiences", null)
          client_secret              = lookup(active_directory.value, "client_secret", null)
          client_secret_setting_name = lookup(active_directory.value, "client_secret_setting_name", null)
        }
      }
    }
  }

  # Auth v2
  dynamic "auth_settings_v2" {
    for_each = lookup(each.value, "auth_settings_v2", null) != null ? [each.value.auth_settings_v2] : []
    content {
      auth_enabled           = lookup(auth_settings_v2.value, "auth_enabled", null)
      runtime_version        = lookup(auth_settings_v2.value, "runtime_version", null)
      config_file_path       = lookup(auth_settings_v2.value, "config_file_path", null)
      require_authentication = lookup(auth_settings_v2.value, "require_authentication", null)
      unauthenticated_action = lookup(auth_settings_v2.value, "unauthenticated_action", null)
      default_provider       = lookup(auth_settings_v2.value, "default_provider", null)
      excluded_paths         = lookup(auth_settings_v2.value, "excluded_paths", null)
      require_https          = lookup(auth_settings_v2.value, "require_https", null)
      http_route_api_prefix  = lookup(auth_settings_v2.value, "http_route_api_prefix", null)
      forward_proxy_convention               = lookup(auth_settings_v2.value, "forward_proxy_convention", null)
      forward_proxy_custom_host_header_name  = lookup(auth_settings_v2.value, "forward_proxy_custom_host_header_name", null)
      forward_proxy_custom_scheme_header_name= lookup(auth_settings_v2.value, "forward_proxy_custom_scheme_header_name", null)

      dynamic "active_directory_v2" {
        for_each = lookup(auth_settings_v2.value, "active_directory_v2", null) != null ? [auth_settings_v2.value.active_directory_v2] : []
        content {
          client_id                            = active_directory_v2.value.client_id
          tenant_auth_endpoint                 = active_directory_v2.value.tenant_auth_endpoint
          client_secret_setting_name           = lookup(active_directory_v2.value, "client_secret_setting_name", null)
          client_secret_certificate_thumbprint = lookup(active_directory_v2.value, "client_secret_certificate_thumbprint", null)
          jwt_allowed_groups                   = lookup(active_directory_v2.value, "jwt_allowed_groups", null)
          jwt_allowed_client_applications      = lookup(active_directory_v2.value, "jwt_allowed_client_applications", null)
          www_authentication_disabled          = lookup(active_directory_v2.value, "www_authentication_disabled", null)
          allowed_groups                       = lookup(active_directory_v2.value, "allowed_groups", null)
          allowed_identities                   = lookup(active_directory_v2.value, "allowed_identities", null)
          allowed_applications                 = lookup(active_directory_v2.value, "allowed_applications", null)
          login_parameters                     = lookup(active_directory_v2.value, "login_parameters", null)
          allowed_audiences                    = lookup(active_directory_v2.value, "allowed_audiences", null)
        }
      }
      # Required when auth_settings_v2 present
      login {
        logout_endpoint                 = lookup(auth_settings_v2.value.login, "logout_endpoint", null)
        token_store_enabled             = lookup(auth_settings_v2.value.login, "token_store_enabled", null)
        token_refresh_extension_time    = lookup(auth_settings_v2.value.login, "token_refresh_extension_time", null)
        token_store_path                = lookup(auth_settings_v2.value.login, "token_store_path", null)
        token_store_sas_setting_name    = lookup(auth_settings_v2.value.login, "token_store_sas_setting_name", null)
        preserve_url_fragments_for_logins = lookup(auth_settings_v2.value.login, "preserve_url_fragments_for_logins", null)
        allowed_external_redirect_urls  = lookup(auth_settings_v2.value.login, "allowed_external_redirect_urls", null)
        cookie_expiration_convention    = lookup(auth_settings_v2.value.login, "cookie_expiration_convention", null)
        cookie_expiration_time          = lookup(auth_settings_v2.value.login, "cookie_expiration_time", null)
        validate_nonce                  = lookup(auth_settings_v2.value.login, "validate_nonce", null)
        nonce_expiration_time           = lookup(auth_settings_v2.value.login, "nonce_expiration_time", null)
      }
    }
  }

  # site_config (required)
    # Emit exactly one site_config block
  site_config {
    always_on                         = try(each.value.site_config.always_on, null)
    http2_enabled                     = try(each.value.site_config.http2_enabled, null)
    minimum_tls_version               = try(each.value.site_config.minimum_tls_version, null)
    use_32_bit_worker                 = try(each.value.site_config.use_32_bit_worker, null)
    ftps_state                        = try(each.value.site_config.ftps_state, null)
    health_check_path                 = try(each.value.site_config.health_check_path, null)
    health_check_eviction_time_in_min = try(each.value.site_config.health_check_eviction_time_in_min, null)
    pre_warmed_instance_count         = try(each.value.site_config.pre_warmed_instance_count, null)
    app_scale_limit                   = try(each.value.site_config.app_scale_limit, null)
    worker_count                      = try(each.value.site_config.worker_count, null)
    application_insights_connection_string = try(each.value.site_config.application_insights_connection_string, null)
    application_insights_key               = try(each.value.site_config.application_insights_key, null)
    load_balancing_mode               = try(each.value.site_config.load_balancing_mode, null)
    managed_pipeline_mode             = try(each.value.site_config.managed_pipeline_mode, null)
    runtime_scale_monitoring_enabled  = try(each.value.site_config.runtime_scale_monitoring_enabled, null)
    scm_minimum_tls_version           = try(each.value.site_config.scm_minimum_tls_version, null)
    scm_use_main_ip_restriction       = try(each.value.site_config.scm_use_main_ip_restriction, null)
    ip_restriction_default_action     = try(each.value.site_config.ip_restriction_default_action, null)
    scm_ip_restriction_default_action = try(each.value.site_config.scm_ip_restriction_default_action, null)

    # Optional: include application_stack only if supplied
    dynamic "application_stack" {
      for_each = try(each.value.site_config.application_stack, null) == null ? [] : [each.value.site_config.application_stack]
      content {
        dotnet_version              = try(application_stack.value.dotnet_version, null)
        use_dotnet_isolated_runtime = try(application_stack.value.use_dotnet_isolated_runtime, null)
        java_version                = try(application_stack.value.java_version, null)
        node_version                = try(application_stack.value.node_version, null)
        powershell_core_version     = try(application_stack.value.powershell_core_version, null)
        use_custom_runtime          = try(application_stack.value.use_custom_runtime, null)
      }
    }

    # Optional: include cors only if supplied
    dynamic "cors" {
      for_each = try(each.value.site_config.cors, null) == null ? [] : [each.value.site_config.cors]
      content {
        allowed_origins     = cors.value.allowed_origins
        support_credentials = try(cors.value.support_credentials, null)
      }
    }
  }

  lifecycle {
    precondition {
      #condition     = alltrue([for v in values(each.value.tags) : trimspace(v) != ""])
      condition     = alltrue([for v in values(each.value.tags) : v == null ? true : trimspace(v) != ""]) # it will not check for optional tag values
      
      error_message = "RG '${each.key}' creation blocked: one or more required tags are empty."
    }
    ignore_changes = [ storage_account_access_key ,
      #Entire site_config ,app_setting ignore (broad but simple): 
      #if want value we remove this get the values
      site_config , app_settings ,
      # Hidden tags when function app is connect to app insights 
      tags["hidden-link: /app-insights-resource-id"],
      tags["hidden-link: /app-insights-conn-string"],
      tags["hidden-link: /app-insights-instrumentation-key"],
      auth_settings_v2

      # OR targeted ignore (narrow):
      # site_config[0].application_insights_connection_string,
      # site_config[0].application_insights_key,
    ]
  }

}

