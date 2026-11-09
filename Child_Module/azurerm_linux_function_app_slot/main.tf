data "azurerm_storage_account" "linux_slot_storage_accounts" {
  for_each = var.linux_function_app_slots
  name                = each.value.storage_account_name
  resource_group_name = each.value.rg_name_stg
}

resource "azurerm_linux_function_app_slot" "linux_function_app_slots" {
  for_each = var.linux_function_app_slots

  name            = each.value.name
  function_app_id = var.linux_function_ids[each.value.existing_func_app_name]

  # Optional override
  service_plan_id = lookup(each.value, "service_plan_id", null)

  # ---------- Storage ----------
  storage_account_name       = lookup(each.value, "storage_account_name", null)
  storage_account_access_key = data.azurerm_storage_account.linux_slot_storage_accounts[each.key].primary_access_key

  # ---------- Core ----------
  app_settings                    = lookup(each.value, "app_settings", {})
  functions_extension_version     = lookup(each.value, "functions_extension_version", null)
  https_only                      = lookup(each.value, "https_only", null)
  enabled                         = lookup(each.value, "enabled", null)
  public_network_access_enabled   = lookup(each.value, "public_network_access_enabled", null)
  tags                            = each.value.tags
  vnet_image_pull_enabled = lookup(each.value, "vnet_image_pull_enabled", null)
  client_certificate_enabled = lookup(each.value, "client_certificate_enabled", null)
  client_certificate_mode    = lookup(each.value, "client_certificate_mode", null)
  builtin_logging_enabled = lookup(each.value, "builtin_logging_enabled", null)
  ftp_publish_basic_authentication_enabled = lookup(each.value, "ftp_publish_basic_authentication_enabled", null)
  webdeploy_publish_basic_authentication_enabled = lookup(each.value, "webdeploy_publish_basic_authentication_enabled", null)
 
  # ---------- Identity ----------
  dynamic "identity" {
    for_each = lookup(each.value, "identity", null) != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = lookup(identity.value, "identity_ids", null)
    }
  }

  # ---------- Auth v1 ----------
  dynamic "auth_settings" {
    for_each = lookup(each.value, "auth_settings", null) != null ? [each.value.auth_settings] : []
    content {
      enabled                       = auth_settings.value.enabled
      default_provider              = lookup(auth_settings.value, "default_provider", null)
      issuer                        = lookup(auth_settings.value, "issuer", null)
      token_store_enabled           = lookup(auth_settings.value, "token_store_enabled", null)
      unauthenticated_client_action = lookup(auth_settings.value, "unauthenticated_client_action", null)
    }
  }

  # ---------- Auth v2 ----------
  dynamic "auth_settings_v2" {
    for_each = lookup(each.value, "auth_settings_v2", null) != null ? [each.value.auth_settings_v2] : []
    content {
      auth_enabled           = lookup(auth_settings_v2.value, "auth_enabled", null)
      runtime_version        = lookup(auth_settings_v2.value, "runtime_version", null)
      require_authentication = lookup(auth_settings_v2.value, "require_authentication", null)
      unauthenticated_action = lookup(auth_settings_v2.value, "unauthenticated_action", null)
      require_https          = lookup(auth_settings_v2.value, "require_https", null)

      dynamic "active_directory_v2" {
        for_each = lookup(auth_settings_v2.value, "active_directory_v2", null) != null ? [auth_settings_v2.value.active_directory_v2] : []
        content {
          client_id            = active_directory_v2.value.client_id
          tenant_auth_endpoint = active_directory_v2.value.tenant_auth_endpoint
          allowed_audiences    = lookup(active_directory_v2.value, "allowed_audiences", null)
        }
      }

      login {
        logout_endpoint              = lookup(auth_settings_v2.value.login, "logout_endpoint", null)
        token_store_enabled          = lookup(auth_settings_v2.value.login, "token_store_enabled", null)
        token_refresh_extension_time = lookup(auth_settings_v2.value.login, "token_refresh_extension_time", null)
      }
    }
  }

  # ---------- Site Config (MANDATORY) ----------
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
      condition     = alltrue([for v in values(each.value.tags) : trimspace(v) != ""])
      error_message = "Linux Function Slot '${each.key}' blocked: required tags are empty."
    }
    ignore_changes = [
      app_settings,
      site_config,
      auth_settings_v2,
      storage_account_access_key,
      tags["hidden-link:/app-insights-resource-id"],
      tags["hidden-link: /app-insights-resource-id"]
    ]
  }
}