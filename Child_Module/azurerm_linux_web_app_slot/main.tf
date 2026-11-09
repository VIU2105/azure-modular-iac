resource "azurerm_linux_web_app_slot" "linux_web_app_slot" {
  for_each = var.linux_web_app_slots

  name           = each.value.name
  app_service_id = var.linux_web_app_ids[each.value.existing_linux_web_app_name]

  # Optional override (rare use-case)
  service_plan_id = lookup(each.value, "service_plan_id", null)

  # ---------- Core toggles ----------
  enabled                       = lookup(each.value, "enabled", true)
  https_only                    = lookup(each.value, "https_only", false)
  public_network_access_enabled = lookup(each.value, "public_network_access_enabled", true)

  client_affinity_enabled      = lookup(each.value, "client_affinity_enabled", null)
  client_certificate_enabled   = lookup(each.value, "client_certificate_enabled", null)
  client_certificate_mode      = lookup(each.value, "client_certificate_mode", null)
  key_vault_reference_identity_id = lookup(each.value, "key_vault_reference_identity_id", null)

  vnet_image_pull_enabled = lookup(each.value, "vnet_image_pull_enabled", null)

  ftp_publish_basic_authentication_enabled       = lookup(each.value, "ftp_publish_basic_authentication_enabled", null)
  webdeploy_publish_basic_authentication_enabled = lookup(each.value, "webdeploy_publish_basic_authentication_enabled", null)

  # ---------- App Settings ----------
  app_settings = lookup(each.value, "app_settings", {})

  # ---------- Connection Strings ----------
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
      issuer                        = lookup(auth_settings.value, "issuer", null)
      default_provider              = lookup(auth_settings.value, "default_provider", null)
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
      require_https          = lookup(auth_settings_v2.value, "require_https", null)
      require_authentication = lookup(auth_settings_v2.value, "require_authentication", null)
      unauthenticated_action = lookup(auth_settings_v2.value, "unauthenticated_action", null)

      login {
        logout_endpoint              = lookup(auth_settings_v2.value.login, "logout_endpoint", null)
        token_store_enabled          = lookup(auth_settings_v2.value.login, "token_store_enabled", null)
        token_refresh_extension_time = lookup(auth_settings_v2.value.login, "token_refresh_extension_time", null)
      }
    }
  }

  # ---------- site_config (MANDATORY) ----------
  site_config {
    always_on           = try(each.value.site_config.always_on, true)
    http2_enabled       = try(each.value.site_config.http2_enabled, null)
    minimum_tls_version = try(each.value.site_config.minimum_tls_version, null)
    ftps_state          = try(each.value.site_config.ftps_state, null)
    health_check_path   = try(each.value.site_config.health_check_path, null)
    worker_count        = try(each.value.site_config.worker_count, null)

    ip_restriction_default_action     = try(each.value.site_config.ip_restriction_default_action, null)
    scm_ip_restriction_default_action = try(each.value.site_config.scm_ip_restriction_default_action, null)

    dynamic "application_stack" {
      for_each = try(each.value.site_config.application_stack, null) == null ? [] : [each.value.site_config.application_stack]
      content {
        dotnet_version              = try(application_stack.value.dotnet_version, null)
        python_version              = try(application_stack.value.python_version, null)
        # use_dotnet_isolated_runtime = try(application_stack.value.use_dotnet_isolated_runtime, null)
        java_version                = try(application_stack.value.java_version, null)
        node_version                = try(application_stack.value.node_version, null)
      }
    }
  }

  tags = each.value.tags

  lifecycle {
    precondition {
      condition     = alltrue([for v in values(each.value.tags) : trimspace(v) != ""])
      error_message = "Linux Web App Slot '${each.key}' blocked: one or more required tags are empty."
    }

    ignore_changes = [
      auth_settings_v2,
      app_settings,
      site_config,
      tags["hidden-link: /app-insights-resource-id"]
      # app_settings["APPINSIGHTS_INSTRUMENTATIONKEY"],
      # app_settings["APPLICATIONINSIGHTS_CONNECTION_STRING"],
      # site_config[0].ip_restriction_default_action,
      # site_config[0].scm_ip_restriction_default_action
    ]
  }
}

# Not Required as of now, but keeping it here for future reference
# output "linux_web_app_slot_ids" {
#   value = {
#     for _, slot in azurerm_linux_web_app_slot.linux_web_app_slot : slot.name => slot.id
#   }
# }
