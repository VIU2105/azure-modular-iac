# Storage account name handling Does NOT manage storage at resource level

resource "azurerm_windows_web_app_slot" "windows_web_app_slots" {
  for_each = var.windows_web_app_slots

  # ---------------- Required ----------------
  name           = each.value.name
  app_service_id = var.windows_web_app_ids[each.value.existing_web_app_name]

  # ---------------- Optional: override plan ----------------
  service_plan_id = lookup(each.value, "service_plan_id", null)

  # ---------------- Core toggles ----------------
  enabled                       = lookup(each.value, "enabled", true)
  https_only                    = lookup(each.value, "https_only", null)
  public_network_access_enabled = lookup(each.value, "public_network_access_enabled", null)
  client_affinity_enabled       = lookup(each.value, "client_affinity_enabled", null)
  
  ftp_publish_basic_authentication_enabled      = lookup(each.value, "ftp_publish_basic_authentication_enabled", null)
  webdeploy_publish_basic_authentication_enabled = lookup(each.value, "webdeploy_publish_basic_authentication_enabled", null)
  client_certificate_enabled         = lookup(each.value, "client_certificate_enabled", null)
  client_certificate_mode            = lookup(each.value, "client_certificate_mode", null)

  app_settings = lookup(each.value, "app_settings", {})

  tags = each.value.tags

  # ---------------- Identity ----------------
  dynamic "identity" {
    for_each = lookup(each.value, "identity", null) != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = lookup(identity.value, "identity_ids", null)
    }
  }

  key_vault_reference_identity_id = lookup(each.value, "key_vault_reference_identity_id", null)

  # ---------------- Connection Strings ----------------
  dynamic "connection_string" {
    for_each = lookup(each.value, "connection_strings", [])
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  # ---------------- Auth v1 ----------------
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

  # ---------------- Auth v2 ----------------
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
  # Blocks of type "sticky_settings" are not expected here

  # ---------------- Site Config (MANDATORY) ----------------
  #   site_config {
  #        always_on             = lookup(each.value.site_config, "always_on", null)
  #        http2_enabled         = lookup(each.value.site_config, "http2_enabled", null)
  #        minimum_tls_version   = lookup(each.value.site_config, "minimum_tls_version", null)
  #        use_32_bit_worker     = lookup(each.value.site_config, "use_32_bit_worker", null)
  #        ftps_state            = lookup(each.value.site_config, "ftps_state", null)
  #        health_check_path     = lookup(each.value.site_config, "health_check_path", null)
  #        worker_count          = lookup(each.value.site_config, "worker_count", null)
  #        ip_restriction_default_action     = lookup(each.value.site_config, "ip_restriction_default_action", null)
  #        scm_ip_restriction_default_action = lookup(each.value.site_config, "scm_ip_restriction_default_action", null)

  #        # Not part of Windows Web App Slots
  #        #pre_warmed_instance_count = lookup(each.value.site_config, "pre_warmed_instance_count", null)
  #        #app_scale_limit       = lookup(each.value.site_config, "app_scale_limit", null)
  #        #application_insights_connection_string = lookup(each.value.site_config,"application_insights_connection_string", null)
  #        #application_insights_key = lookup(each.value.site_config,"application_insights_key", null)
  # }

  site_config {
    # we are using try beacuse as it's nested loop
    always_on           = try(each.value.site_config.always_on, null)
    http2_enabled       = try(each.value.site_config.http2_enabled, null)
    minimum_tls_version = try(each.value.site_config.minimum_tls_version, null)
    ftps_state          = try(each.value.site_config.ftps_state, null)
    use_32_bit_worker   = try(each.value.site_config.use_32_bit_worker, null)
    websockets_enabled = try(each.value.site_config.websockets_enabled, null)
    health_check_path  = try(each.value.site_config.health_check_path, null)
    worker_count       = try(each.value.site_config.worker_count, null)
    # Not required for linux web app (keeping commented as-is)
    # application_insights_connection_string = try(each.value.site_config.application_insights_connection_string, null)
    # application_insights_key               = try(each.value.site_config.application_insights_key, null)

    ip_restriction_default_action     = try(each.value.site_config.ip_restriction_default_action, null)
    scm_ip_restriction_default_action = try(each.value.site_config.scm_ip_restriction_default_action, null)

    #   # ---------- Application Stack ----------
    # dynamic "application_stack" {
    #   for_each = try(each.value.site_config.application_stack, null) != null ? [each.value.site_config.application_stack] : []
    #   content {
    #     current_stack       = lookup(application_stack.value, "current_stack", null)
    #     dotnet_version      = lookup(application_stack.value, "dotnet_version", null)
    #     dotnet_core_version = lookup(application_stack.value, "dotnet_core_version", null)
    #     node_version        = lookup(application_stack.value, "node_version", null)
    #     java_version        = lookup(application_stack.value, "java_version", null)
    #     php_version         = lookup(application_stack.value, "php_version", null)
    #     python              = lookup(application_stack.value, "python", null)
    #   }
    # }

    # # ---------- CORS ----------
    # dynamic "cors" {
    #   for_each = try(each.value.site_config.cors, null) != null ? [each.value.site_config.cors] : []
    #   content {
    #     allowed_origins     = cors.value.allowed_origins
    #     support_credentials = lookup(cors.value, "support_credentials", null)
    #   }
    # }
  }

  lifecycle {
    precondition {
      condition     = alltrue([for v in values(each.value.tags) : trimspace(v) != ""])
      error_message = "Windows Web App Slot '${each.key}' blocked: required tags are empty."
    }

    ignore_changes = [
      app_settings,
      site_config,
      tags["hidden-link:/app-insights-resource-id"],
      tags["hidden-link: /app-insights-resource-id"],
      tags["hidden-link: /app-insights-conn-string"],
      tags["hidden-link: /app-insights-instrumentation-key"],
      auth_settings_v2
    ]
  }
}