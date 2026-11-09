# data  "azurerm_service_plan" "service_plan" {
#     # To get the Service Plan ID
#     for_each = var.windows_function_apps
#   name                = each.value.existing_sp_name
#   resource_group_name = each.value.existing_sp_rg
# }

data "azurerm_storage_account" "storage_accounts" {
  # To Get the Storage Account Details if required
  for_each = var.windows_function_apps
  name                = each.value.storage_account_name
  resource_group_name = each.value.rg_name_stg
}

resource "azurerm_windows_function_app" "windows_function_app" {
  for_each = var.windows_function_apps

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  # Here we are linked the Function App -> Service Plan, this value we are calling from the output block define in the service child block and passing the value in the window_function_app module
  service_plan_id = var.service_app_ids[each.value.existing_sp_name]
  # service_plan_id     = data.azurerm_service_plan.service_plan[each.key].id

  # ---------- Storage patterns ----------
  storage_account_name           = lookup(each.value, "storage_account_name", null)
  storage_account_access_key = data.azurerm_storage_account.storage_accounts[each.key].primary_access_key
  #storage_account_access_key     = lookup(each.value, "storage_account_access_key", null)    # conflicts with storage_uses_managed_identity
  
  # ---------- Core toggles ----------
  functions_extension_version      = lookup(each.value, "functions_extension_version", null)
  https_only                       = lookup(each.value, "https_only", null)
  public_network_access_enabled    = lookup(each.value, "public_network_access_enabled", null)
  builtin_logging_enabled          = lookup(each.value, "builtin_logging_enabled", null)
  enabled                          = lookup(each.value, "enabled", null)
  key_vault_reference_identity_id  = lookup(each.value, "key_vault_reference_identity_id", null)
  client_certificate_mode          = each.value.client_certificate_mode
  vnet_image_pull_enabled          = each.value.vnet_image_pull_enabled
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

  # ---------- App settings & connection strings ----------

  app_settings = lookup(each.value, "app_settings", null)

  dynamic "connection_string" {
    for_each = each.value.connection_strings != null ? each.value.connection_strings : []
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = sensitive(connection_string.value.value)
    }
  }

  # Extra storage mounts
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

  # ---------- site_config (Required) ----------
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
    always_on           = try(each.value.site_config.always_on, null)
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
  }

  # ---------- Auth (v1 & v2) ----------
  dynamic "auth_settings" {
    for_each = lookup(each.value, "auth_settings", null) != null ? [ each.value.auth_settings ] : []
    content {
      enabled                       = auth_settings.value.enabled
      default_provider              = lookup(auth_settings.value, "default_provider", null)
      issuer                        = lookup(auth_settings.value, "issuer", null)
      token_store_enabled           = lookup(auth_settings.value, "token_store_enabled", null)
      unauthenticated_client_action = lookup(auth_settings.value, "unauthenticated_client_action", null)
      token_refresh_extension_hours = lookup(auth_settings.value, "token_refresh_extension_hours", null)
    }
  }

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
      # condition     = alltrue([for v in values(each.value.tags) : trimspace(v) != ""]) # it will check all the tags value if any of the tag value is empty then it will not create the resource and throw error message
      condition     = alltrue([for v in values(each.value.tags) : v == null ? true : trimspace(v) != ""]) # it will not check for optional tag values
      
      error_message = "RG '${each.key}' creation blocked: one or more required tags are empty."
    }
    ignore_changes = [ 
      #Entire auth_settings_v2 , sticky_settings site_config , app_settings , ignore (broad but simple): 
      #if want value we remove this get the values
      auth_settings_v2, sticky_settings , site_config , app_settings , storage_account_access_key ,
      tags["hidden-link: /app-insights-resource-id"],
      tags["hidden-related:diagnostics/changeAnalysisScanEnabled"],
      # tags["hidden-*"]
      tags["hidden-link: /app-insights-instrumentation-key"],
      tags["hidden-link: /app-insights-conn-string"],
      identity

      # OR targeted ignore (narrow):
      # site_config[0].application_insights_connection_string,
      # site_config[0].application_insights_key,
      # it's Hidden tag which azutre Automatically create as it is internally linked with app insight which was not recommed to delete
      # tags["hidden-link:/app-insights-resource-id"] ,

    ]   
  }

}

# output "function_app_ids" {
# value = {for k,v in azurerm_windows_function_app.windows_function_app: k=> v.id}
  
# }

output "function_app_ids" {
  description = "Map of service plan IDs created in this ASE"
  value = { for _, fa in azurerm_windows_function_app.windows_function_app : fa.name => fa.id }
 
 # key is ignore by _ and manually fetching it's value here fa.name is function name which is fa.<attribute>
  
}
