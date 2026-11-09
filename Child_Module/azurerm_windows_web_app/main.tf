# Storage account name handling Does NOT manage storage at resource level

resource "azurerm_windows_web_app" "windows_web_app" {
  for_each = var.windows_web_apps

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  service_plan_id = var.service_app_ids[each.value.existing_sp_name]

  # ---------- Core toggles ----------
  enabled                       = lookup(each.value, "enabled", true)
  https_only                    = lookup(each.value, "https_only", true)
  public_network_access_enabled = lookup(each.value, "public_network_access_enabled", true)
  client_affinity_enabled       = lookup(each.value, "client_affinity_enabled", null)
  key_vault_reference_identity_id  = lookup(each.value, "key_vault_reference_identity_id", null)

  #vnet_image_pull_enabled          = each.value.vnet_image_pull_enabled
  # Client cert
  client_certificate_mode          = lookup(each.value, "client_certificate_mode", null)
  client_certificate_enabled = lookup(each.value, "client_certificate_enabled", null)
  ftp_publish_basic_authentication_enabled = lookup(each.value, "ftp_publish_basic_authentication_enabled", null)
  webdeploy_publish_basic_authentication_enabled = lookup(each.value, "webdeploy_publish_basic_authentication_enabled", null)
  
  # ---------- App Settings ----------
  app_settings = lookup(each.value, "app_settings", {})

    # ---------------- Connection Strings ----------------
   dynamic "connection_string" {
    for_each = lookup(each.value, "connection_strings", [])
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

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
  #     worker_count          = lookup(site_config.value, "worker_count", null)

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
    # Not required for linux web app (keeping commented as-is)
    # application_insights_connection_string = try(each.value.site_config.application_insights_connection_string, null)
    # application_insights_key               = try(each.value.site_config.application_insights_key, null)

    ip_restriction_default_action     = try(each.value.site_config.ip_restriction_default_action, null)
    scm_ip_restriction_default_action = try(each.value.site_config.scm_ip_restriction_default_action, null)
  }
  # ✅ Same tag handling as Function App
  tags = each.value.tags

  lifecycle {
    precondition {
      # condition     = alltrue([for v in values(each.value.tags) : trimspace(v) != ""])
      condition     = alltrue([for v in values(each.value.tags) : v == null ? true : trimspace(v) != ""]) # it will not check for optional tag values
      
      
      error_message = "Windows Web App '${each.key}' blocked: one or more required tags are empty."
    }

    ignore_changes = [
      auth_settings_v2,
      sticky_settings,
      app_settings,
      site_config,
      tags["hidden-link: /app-insights-resource-id"]
    ]
  }
}

output "windows_web_app_ids" {
  description = "Windows Web App IDs"
  value = {
    for _, app in azurerm_windows_web_app.windows_web_app : app.name => app.id }
}
