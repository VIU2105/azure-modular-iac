data "azurerm_storage_account" "linux_storage_accounts" {
  for_each = var.linux_function_apps
  name                = each.value.storage_account_name
  resource_group_name = each.value.rg_name_stg
}

resource "azurerm_linux_function_app" "linux_function_app" {
  for_each = var.linux_function_apps

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  service_plan_id = var.service_app_ids[each.value.existing_sp_name]

  # ---------- Storage ----------
  storage_account_name       = each.value.storage_account_name
  storage_account_access_key = data.azurerm_storage_account.linux_storage_accounts[each.key].primary_access_key

  # ---------- Core toggles ----------
  functions_extension_version   = lookup(each.value, "functions_extension_version", "~4")
  https_only                    = lookup(each.value, "https_only", true)
  public_network_access_enabled = lookup(each.value, "public_network_access_enabled", true)
  enabled                       = lookup(each.value, "enabled", true)
  vnet_image_pull_enabled = lookup(each.value, "vnet_image_pull_enabled", null)

  # Client cert
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

  # ---------- App Settings ----------
  app_settings = lookup(each.value, "app_settings", {})

  # ---------- site_config (MANDATORY) ----------

  # dynamic "site_config" {
  #   # If absent, we still emit one empty block so the resource meets the provider's required "site_config" constraint
  #   for_each = lookup(each.value, "site_config", null) != null ? [each.value.site_config] : [ {} ]
  #   content {
  #     always_on             = lookup(site_config.value, "always_on", null)
  #     http2_enabled         = lookup(site_config.value, "http2_enabled", null)
  #     minimum_tls_version   = lookup(site_config.value, "minimum_tls_version", null)
  #     use_32_bit_worker     = lookup(site_config.value, "use_32_bit_worker", null)
  #     ftps_state            = lookup(site_config.value, "ftps_state", null)
  #     health_check_path     = lookup(site_config.value, "health_check_path", null)
  #     pre_warmed_instance_count = lookup(site_config.value, "pre_warmed_instance_count", null)
  #     app_scale_limit       = lookup(site_config.value, "app_scale_limit", null)
  #     worker_count          = lookup(site_config.value, "worker_count", null)

  #     application_insights_connection_string = lookup(site_config.value, "application_insights_connection_string", null)
  #     application_insights_key               = lookup(site_config.value, "application_insights_key", null)

  #     ip_restriction_default_action     = lookup(site_config.value, "ip_restriction_default_action", null)
  #     scm_ip_restriction_default_action = lookup(site_config.value, "scm_ip_restriction_default_action", null)
  #   }
  # }
  site_config {
    # we are using try beacuse as it's nested loop
    always_on           = try(each.value.site_config.always_on, true)
    http2_enabled       = try(each.value.site_config.http2_enabled, null)
    minimum_tls_version = try(each.value.site_config.minimum_tls_version, null)
    use_32_bit_worker   = try(each.value.site_config.use_32_bit_worker, null)
    ftps_state          = try(each.value.site_config.ftps_state, null)
    health_check_path   = try(each.value.site_config.health_check_path, null)
    worker_count        = try(each.value.site_config.worker_count, null)
    application_insights_connection_string = try(each.value.site_config.application_insights_connection_string, null)
    application_insights_key               = try(each.value.site_config.application_insights_key, null)

    ip_restriction_default_action     = try(each.value.site_config.ip_restriction_default_action, null)
    scm_ip_restriction_default_action = try(each.value.site_config.scm_ip_restriction_default_action, null)

    dynamic "application_stack" {
      for_each = lookup(lookup(each.value, "site_config", {}),"application_stack",null) != null ? [each.value.site_config.application_stack] : []
      content {
        dotnet_version = lookup(application_stack.value, "dotnet_version", null)
        node_version   = lookup(application_stack.value, "node_version", null)
        python_version = lookup(application_stack.value, "python_version", null)
        java_version   = lookup(application_stack.value, "java_version", null)
      }
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
      token_refresh_extension_hours = lookup(auth_settings.value, "token_refresh_extension_hours", null)
    }
  }
  # ---------- Auth v2 ----------

  dynamic "auth_settings_v2" {
    for_each = lookup(each.value, "auth_settings_v2", null) != null ? [each.value.auth_settings_v2] : []
    content {
      auth_enabled           = lookup(auth_settings_v2.value, "auth_enabled", null)
      runtime_version        = lookup(auth_settings_v2.value, "runtime_version", null)
      require_https          = lookup(auth_settings_v2.value, "require_https", null)
      require_authentication = lookup(auth_settings_v2.value, "require_authentication", null)
      unauthenticated_action = lookup(auth_settings_v2.value, "unauthenticated_action", null)
      
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
      # As login block keep static
      login {
        logout_endpoint              = lookup(auth_settings_v2.value.login, "logout_endpoint", null)
        token_store_enabled          = lookup(auth_settings_v2.value.login, "token_store_enabled", null)
        token_refresh_extension_time = lookup(auth_settings_v2.value.login, "token_refresh_extension_time", null)
      }
    }
  }

  tags = each.value.tags

  lifecycle {
    precondition {
      # condition     = alltrue([for v in values(each.value.tags) : trimspace(v) != ""])
      condition     = alltrue([for v in values(each.value.tags) : v == null ? true : trimspace(v) != ""]) # it will not check for optional tag values
      
      error_message = "RG '${each.key}' creation blocked: one or more required tags are empty."
    }
    ignore_changes = [
      auth_settings_v2,
      sticky_settings,
      app_settings,
      site_config,
      storage_account_access_key,
      tags["hidden-link: /app-insights-resource-id"],
      tags["hidden-link: /app-insights-conn-string"],
      tags["hidden-link: /app-insights-instrumentation-key"]
    ]
  }
}

output "linux_function_app_ids" {
  description = "Linux Function App IDs"
  value = { for _, fa in azurerm_linux_function_app.linux_function_app : fa.name => fa.id }
}

# This output block for principal IDs is commented out it's part of the  kv access policy because it is not required for the current setup.
# output "linux_function_app_principal_ids" {
#   value = {
#     for _, fa in azurerm_linux_function_app.linux_function_app :
#     fa.name => try(fa.identity[0].principal_id, null)
#   }
# }

# Not required as tenant id is fixed for this subscription
# output "linux_function_app_tenant_ids" {
#   value = {
#     for _, fa in azurerm_linux_function_app.linux_function_app :
#     fa.name => try(fa.identity[0].tenant_id, null)
#   }
# }