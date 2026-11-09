resource "azurerm_kubernetes_cluster" "aks" {
  for_each = var.kubernetes_clusters

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  dns_prefix                 = try(each.value.dns_prefix, null)
  dns_prefix_private_cluster = try(each.value.dns_prefix_private_cluster, null)

  kubernetes_version                  = try(each.value.kubernetes_version, null)
  automatic_upgrade_channel           = try(each.value.automatic_upgrade_channel, null)
  node_os_upgrade_channel             = try(each.value.node_os_upgrade_channel, null)
  sku_tier                            = try(each.value.sku_tier, null)
  support_plan                        = try(each.value.support_plan, null)
  node_resource_group                 = try(each.value.node_resource_group, null)
  private_cluster_enabled             = try(each.value.private_cluster_enabled, null)
  private_dns_zone_id                 = try(each.value.private_dns_zone_id, null)
  private_cluster_public_fqdn_enabled = try(each.value.private_cluster_public_fqdn_enabled, null)

  role_based_access_control_enabled = try(each.value.role_based_access_control_enabled, null)
  local_account_disabled            = try(each.value.local_account_disabled, null)

  azure_policy_enabled      = try(each.value.azure_policy_enabled, null)
  oidc_issuer_enabled       = try(each.value.oidc_issuer_enabled, null)
  workload_identity_enabled = try(each.value.workload_identity_enabled, null)

  run_command_enabled            = try(each.value.run_command_enabled, null)
  image_cleaner_enabled          = try(each.value.image_cleaner_enabled, null)
  image_cleaner_interval_hours   = try(each.value.image_cleaner_interval_hours, null)
  cost_analysis_enabled          = try(each.value.cost_analysis_enabled, null)

  # ---------------- DEFAULT NODE POOL ----------------

  default_node_pool {
    name    = each.value.default_node_pool.name
    vm_size = try(each.value.default_node_pool.vm_size, null)

    node_count         = try(each.value.default_node_pool.node_count, null)
    auto_scaling_enabled = try(each.value.default_node_pool.auto_scaling_enabled, null)
    min_count          = try(each.value.default_node_pool.min_count, null)
    max_count          = try(each.value.default_node_pool.max_count, null)

    vnet_subnet_id = try(each.value.default_node_pool.vnet_subnet_id, null)
    pod_subnet_id  = try(each.value.default_node_pool.pod_subnet_id, null)

    zones       = try(each.value.default_node_pool.zones, null)
    node_labels = try(each.value.default_node_pool.node_labels, null)

    max_pods = try(each.value.default_node_pool.max_pods, null)

    os_disk_size_gb = try(each.value.default_node_pool.os_disk_size_gb, null)
    os_disk_type    = try(each.value.default_node_pool.os_disk_type, null)
    os_sku          = try(each.value.default_node_pool.os_sku, null)

    host_encryption_enabled      = try(each.value.default_node_pool.host_encryption_enabled, null)
    node_public_ip_enabled       = try(each.value.default_node_pool.node_public_ip_enabled, null)
    only_critical_addons_enabled = try(each.value.default_node_pool.only_critical_addons_enabled, null)

    temporary_name_for_rotation = try(each.value.default_node_pool.temporary_name_for_rotation, null)

    # ---------------------------------------------------------
    # Upgrade Settings
    # ---------------------------------------------------------

    dynamic "upgrade_settings" {
      for_each = try(each.value.default_node_pool.upgrade_settings, null) == null ? [] : [each.value.default_node_pool.upgrade_settings]

      content {
        max_surge                     = upgrade_settings.value.max_surge
        drain_timeout_in_minutes      = try(upgrade_settings.value.drain_timeout_in_minutes, null)
        node_soak_duration_in_minutes = try(upgrade_settings.value.node_soak_duration_in_minutes, null)
        undrainable_node_behavior     = try(upgrade_settings.value.undrainable_node_behavior, null)
      }
    }
  }

  # ---------------- IDENTITY ----------------

  dynamic "identity" {
    for_each = try(each.value.identity, null) == null ? [] : [each.value.identity]

    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  # ---------------- SERVICE PRINCIPAL ----------------

  dynamic "service_principal" {
    for_each = try(each.value.service_principal, null) == null ? [] : [each.value.service_principal]

    content {
      client_id     = service_principal.value.client_id
      client_secret = service_principal.value.client_secret
    }
  }

  # ---------------- NETWORK PROFILE ----------------

  dynamic "network_profile" {
    for_each = try(each.value.network_profile, null) == null ? [] : [each.value.network_profile]

    content {
      network_plugin      = network_profile.value.network_plugin
      network_plugin_mode = try(network_profile.value.network_plugin_mode, null)
      network_policy      = try(network_profile.value.network_policy, null)
      network_data_plane  = try(network_profile.value.network_data_plane, null)

      dns_service_ip = try(network_profile.value.dns_service_ip, null)

      pod_cidr  = try(network_profile.value.pod_cidr, null)
      pod_cidrs = try(network_profile.value.pod_cidrs, null)

      service_cidr  = try(network_profile.value.service_cidr, null)
      service_cidrs = try(network_profile.value.service_cidrs, null)

      ip_versions  = try(network_profile.value.ip_versions, null)
      outbound_type = try(network_profile.value.outbound_type, null)

      load_balancer_sku = try(network_profile.value.load_balancer_sku, null)

      dynamic "load_balancer_profile" {
        for_each = try(network_profile.value.load_balancer_profile, null) == null ? [] : [network_profile.value.load_balancer_profile]

        content {
          backend_pool_type           = try(load_balancer_profile.value.backend_pool_type, null)
          idle_timeout_in_minutes     = try(load_balancer_profile.value.idle_timeout_in_minutes, null)
          managed_outbound_ip_count   = try(load_balancer_profile.value.managed_outbound_ip_count, null)
          managed_outbound_ipv6_count = try(load_balancer_profile.value.managed_outbound_ipv6_count, null)
          outbound_ip_address_ids     = try(load_balancer_profile.value.outbound_ip_address_ids, null)
          outbound_ip_prefix_ids      = try(load_balancer_profile.value.outbound_ip_prefix_ids, null)
          outbound_ports_allocated    = try(load_balancer_profile.value.outbound_ports_allocated, null)
        }
      }

      dynamic "nat_gateway_profile" {
        for_each = try(network_profile.value.nat_gateway_profile, null) == null ? [] : [network_profile.value.nat_gateway_profile]

        content {
          idle_timeout_in_minutes   = try(nat_gateway_profile.value.idle_timeout_in_minutes, null)
          managed_outbound_ip_count = try(nat_gateway_profile.value.managed_outbound_ip_count, null)
        }
      }
    }
  }

  # ---------------- API SERVER ----------------

  dynamic "api_server_access_profile" {
    for_each = try(each.value.api_server_access_profile, null) == null ? [] : [each.value.api_server_access_profile]

    content {
      authorized_ip_ranges               = try(api_server_access_profile.value.authorized_ip_ranges, null)
      subnet_id                          = try(api_server_access_profile.value.subnet_id, null)
      virtual_network_integration_enabled = try(api_server_access_profile.value.virtual_network_integration_enabled, null)
    }
  }

  # ---------------- ENTRA / RBAC ----------------

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = try(each.value.azure_active_directory_role_based_access_control, null) == null ? [] : [each.value.azure_active_directory_role_based_access_control]

    content {
      tenant_id              = try(azure_active_directory_role_based_access_control.value.tenant_id, null)
      admin_group_object_ids = try(azure_active_directory_role_based_access_control.value.admin_group_object_ids, null)
      azure_rbac_enabled     = try(azure_active_directory_role_based_access_control.value.azure_rbac_enabled, null)
    }
  }


  # ---------------- KEY VAULT CSI ----------------

  dynamic "key_vault_secrets_provider" {
    for_each = try(each.value.key_vault_secrets_provider, null) == null ? [] : [each.value.key_vault_secrets_provider]

    content {
      secret_rotation_enabled  = try(key_vault_secrets_provider.value.secret_rotation_enabled, null)
      secret_rotation_interval = try(key_vault_secrets_provider.value.secret_rotation_interval, null)
    }
  }

  # ---------------- MONITOR METRICS ----------------

  dynamic "monitor_metrics" {
    for_each = try(each.value.monitor_metrics, null) == null ? [] : [each.value.monitor_metrics]

    content {
      annotations_allowed = try(monitor_metrics.value.annotations_allowed, null)
      labels_allowed      = try(monitor_metrics.value.labels_allowed, null)
    }
  }

  # ---------------- AUTOSCALER ----------------

  dynamic "auto_scaler_profile" {
    for_each = try(each.value.auto_scaler_profile, null) == null ? [] : [each.value.auto_scaler_profile]

    content {
      balance_similar_node_groups      = try(auto_scaler_profile.value.balance_similar_node_groups, null)
      expander                         = try(auto_scaler_profile.value.expander, null)
      max_graceful_termination_sec     = try(auto_scaler_profile.value.max_graceful_termination_sec, null)
      max_node_provisioning_time       = try(auto_scaler_profile.value.max_node_provisioning_time, null)
      max_unready_nodes                = try(auto_scaler_profile.value.max_unready_nodes, null)
      max_unready_percentage           = try(auto_scaler_profile.value.max_unready_percentage, null)
      new_pod_scale_up_delay           = try(auto_scaler_profile.value.new_pod_scale_up_delay, null)
      scale_down_delay_after_add       = try(auto_scaler_profile.value.scale_down_delay_after_add, null)
      scale_down_delay_after_delete    = try(auto_scaler_profile.value.scale_down_delay_after_delete, null)
      scale_down_delay_after_failure   = try(auto_scaler_profile.value.scale_down_delay_after_failure, null)
      scan_interval                    = try(auto_scaler_profile.value.scan_interval, null)
      scale_down_unneeded              = try(auto_scaler_profile.value.scale_down_unneeded, null)
      scale_down_unready               = try(auto_scaler_profile.value.scale_down_unready, null)
      scale_down_utilization_threshold = try(auto_scaler_profile.value.scale_down_utilization_threshold, null)
      empty_bulk_delete_max            = try(auto_scaler_profile.value.empty_bulk_delete_max, null)
      skip_nodes_with_local_storage    = try(auto_scaler_profile.value.skip_nodes_with_local_storage, null)
      skip_nodes_with_system_pods      = try(auto_scaler_profile.value.skip_nodes_with_system_pods, null)
    }
  }

  # ---------------- WORKLOAD AUTOSCALER ----------------

  dynamic "workload_autoscaler_profile" {
    for_each = try(each.value.workload_autoscaler_profile, null) == null ? [] : [each.value.workload_autoscaler_profile]

    content {
      keda_enabled                    = try(workload_autoscaler_profile.value.keda_enabled, null)
      vertical_pod_autoscaler_enabled = try(workload_autoscaler_profile.value.vertical_pod_autoscaler_enabled, null)
    }
  }

  # ---------------- STORAGE ----------------

  dynamic "storage_profile" {
    for_each = try(each.value.storage_profile, null) == null ? [] : [each.value.storage_profile]

    content {
      blob_driver_enabled         = try(storage_profile.value.blob_driver_enabled, null)
      disk_driver_enabled         = try(storage_profile.value.disk_driver_enabled, null)
      file_driver_enabled         = try(storage_profile.value.file_driver_enabled, null)
      snapshot_controller_enabled = try(storage_profile.value.snapshot_controller_enabled, null)
    }
  }

  # ---------------- LINUX PROFILE ----------------

  dynamic "linux_profile" {
    for_each = try(each.value.linux_profile, null) == null ? [] : [each.value.linux_profile]

    content {
      admin_username = linux_profile.value.admin_username

      ssh_key {
        key_data = linux_profile.value.ssh_key.key_data
      }
    }
  }

  tags = try(each.value.tags, {})

   lifecycle {
    precondition {
      # condition     = alltrue([for v in values(each.value.tags) : trimspace(v) != ""]) # it will check all the tags value if any of the tag value is empty then it will not create the resource and throw error message
      condition     = alltrue([for v in values(each.value.tags) : v == null ? true : trimspace(v) != ""]) # it will not check for optional tag values
      
      error_message = "RG '${each.key}' creation blocked: one or more required tags are empty."
    }
    ignore_changes = [  ]   
  }
}


output "kubernetes_cluster_ids" {
  description = "AKS Cluster IDs"

  value = {
    for key, cluster in azurerm_kubernetes_cluster.aks : key => cluster.id
  }
}

output "kubernetes_cluster_names" {
  description = "AKS Cluster Names"

  value = {
    for key, cluster in azurerm_kubernetes_cluster.aks : key => cluster.name
  }
}