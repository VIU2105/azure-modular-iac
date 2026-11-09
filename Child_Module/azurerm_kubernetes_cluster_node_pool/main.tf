resource "azurerm_kubernetes_cluster_node_pool" "node_pool" {
for_each = var.kubernetes_node_pools

  # =========================================================
  # Required
  # =========================================================

  name = each.value.name

  kubernetes_cluster_id = var.kubernetes_cluster_ids[each.value.existing_aks_name]

  # =========================================================
  # Core Pool Configuration
  # =========================================================

  vm_size = each.value.vm_size

  node_count = try(each.value.node_count,null)

  mode = try(each.value.mode,null)

  auto_scaling_enabled = try(each.value.auto_scaling_enabled,null)

  min_count = try(each.value.min_count,null)

  max_count = try(each.value.max_count,null)

  max_pods = try(each.value.max_pods,null)

  orchestrator_version = try(each.value.orchestrator_version,null)

  # =========================================================
  # Networking
  # =========================================================

  vnet_subnet_id = try(each.value.vnet_subnet_id,null)

  pod_subnet_id = try(each.value.pod_subnet_id,null)

  zones = try(each.value.zones,null)

  # =========================================================
  # Node Configuration
  # =========================================================

  node_labels = try(each.value.node_labels,null)

  node_taints = try(each.value.node_taints,null)

  host_encryption_enabled = try(each.value.host_encryption_enabled,null)

  node_public_ip_enabled = try(each.value.node_public_ip_enabled,null)

  node_public_ip_prefix_id = try(each.value.node_public_ip_prefix_id,null)

  fips_enabled = try(each.value.fips_enabled,null)

  ultra_ssd_enabled = try(each.value.ultra_ssd_enabled,null)

  # =========================================================
  # OS Configuration
  # =========================================================

  os_type = try(each.value.os_type,null)

  os_sku = try(each.value.os_sku,null)

  os_disk_size_gb = try(each.value.os_disk_size_gb,null)

  os_disk_type = try(each.value.os_disk_type,null)

  kubelet_disk_type = try(each.value.kubelet_disk_type,null)

  # =========================================================
  # Rotation
  # =========================================================

  temporary_name_for_rotation = try(each.value.temporary_name_for_rotation,null)

  # =========================================================
  # Upgrade Settings
  # =========================================================

  dynamic "upgrade_settings" {
    for_each = try(each.value.upgrade_settings, null) != null ? [
      each.value.upgrade_settings
    ] : []

    content {
      max_surge = upgrade_settings.value.max_surge

      drain_timeout_in_minutes = try(upgrade_settings.value.drain_timeout_in_minutes,null)

      node_soak_duration_in_minutes = try(upgrade_settings.value.node_soak_duration_in_minutes,null)

      undrainable_node_behavior = try(upgrade_settings.value.undrainable_node_behavior,null)
    }
  }

  # =========================================================
  # Kubelet Config
  # =========================================================

  dynamic "kubelet_config" {
    for_each = try(each.value.kubelet_config, null) != null ? [each.value.kubelet_config] : []

    content {
      allowed_unsafe_sysctls = try(kubelet_config.value.allowed_unsafe_sysctls,null)

      # container_log_max_files = try(
      #   kubelet_config.value.container_log_max_files,
      #   null
      # )

      container_log_max_size_mb = try(kubelet_config.value.container_log_max_size_mb,null)

      cpu_cfs_quota_enabled = try(kubelet_config.value.cpu_cfs_quota_enabled,null)

      cpu_cfs_quota_period = try(kubelet_config.value.cpu_cfs_quota_period,null)

      cpu_manager_policy = try(kubelet_config.value.cpu_manager_policy,null)

      image_gc_high_threshold = try(kubelet_config.value.image_gc_high_threshold,null)

      image_gc_low_threshold = try(kubelet_config.value.image_gc_low_threshold,null)

      pod_max_pid = try(kubelet_config.value.pod_max_pid,null)

      topology_manager_policy = try(kubelet_config.value.topology_manager_policy,null)
    }
  }

  # =========================================================
  # Linux OS Configuration
  # =========================================================

  dynamic "linux_os_config" {
    for_each = try(each.value.linux_os_config, null) != null ? [
      each.value.linux_os_config
    ] : []

    content {
      swap_file_size_mb = try(
        linux_os_config.value.swap_file_size_mb,
        null
      )

      transparent_huge_page = try(
        linux_os_config.value.transparent_huge_page,
        null
      )

      transparent_huge_page_defrag = try(
        linux_os_config.value.transparent_huge_page_defrag,
        null
      )

      dynamic "sysctl_config" {
        for_each = try(linux_os_config.value.sysctl_config, null) != null ? [
          linux_os_config.value.sysctl_config
        ] : []

        content {
          fs_aio_max_nr               = try(sysctl_config.value.fs_aio_max_nr, null)
          fs_file_max                 = try(sysctl_config.value.fs_file_max, null)
          fs_inotify_max_user_watches = try(sysctl_config.value.fs_inotify_max_user_watches, null)
          fs_nr_open                  = try(sysctl_config.value.fs_nr_open, null)

          net_core_netdev_max_backlog = try(sysctl_config.value.net_core_netdev_max_backlog, null)
          net_core_rmem_max           = try(sysctl_config.value.net_core_rmem_max, null)
          net_core_somaxconn          = try(sysctl_config.value.net_core_somaxconn, null)
          net_core_wmem_max           = try(sysctl_config.value.net_core_wmem_max, null)

          net_ipv4_tcp_fin_timeout      = try(sysctl_config.value.net_ipv4_tcp_fin_timeout, null)
          net_ipv4_tcp_keepalive_intvl  = try(sysctl_config.value.net_ipv4_tcp_keepalive_intvl, null)
          net_ipv4_tcp_keepalive_probes = try(sysctl_config.value.net_ipv4_tcp_keepalive_probes, null)
          net_ipv4_tcp_keepalive_time   = try(sysctl_config.value.net_ipv4_tcp_keepalive_time, null)
          net_ipv4_tcp_max_syn_backlog  = try(sysctl_config.value.net_ipv4_tcp_max_syn_backlog, null)

          vm_max_map_count      = try(sysctl_config.value.vm_max_map_count, null)
          vm_swappiness         = try(sysctl_config.value.vm_swappiness, null)
          vm_vfs_cache_pressure = try(sysctl_config.value.vm_vfs_cache_pressure, null)
        }
      }
    }
  }

  tags = try(each.value.tags, {})
}

output "kubernetes_node_pool_ids" {
  description = "AKS Node Pool IDs"

  value = {
    for key, pool in azurerm_kubernetes_cluster_node_pool.node_pool :
    key => pool.id
  }
}