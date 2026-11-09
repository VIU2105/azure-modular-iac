variable "kubernetes_cluster_ids" {
  description = "Map of AKS Cluster IDs"
  type        = map(string)
}


variable "kubernetes_node_pools" {
  description = "Map of additional AKS Node Pools"

  type = map(object({

    # Reference key
    existing_aks_name = string

    # Required
    name    = string
    vm_size = string

    # Node sizing
    node_count = optional(number)

    mode = optional(string, "User")

    auto_scaling_enabled = optional(bool)
    min_count            = optional(number)
    max_count            = optional(number)

    max_pods = optional(number)

    orchestrator_version = optional(string)

    # Networking
    vnet_subnet_id = optional(string)
    pod_subnet_id  = optional(string)

    zones = optional(list(string), [])

    # Node metadata
    node_labels = optional(map(string), {})
    node_taints = optional(list(string), [])

    # Security
    host_encryption_enabled = optional(bool)
    node_public_ip_enabled  = optional(bool)
    node_public_ip_prefix_id = optional(string)
    fips_enabled             = optional(bool)
    ultra_ssd_enabled        = optional(bool)

    # OS
    os_type = optional(string, "Linux")
    os_sku  = optional(string)

    os_disk_size_gb = optional(number)
    os_disk_type    = optional(string)

    kubelet_disk_type = optional(string)

    temporary_name_for_rotation = optional(string)

    # Upgrade
    upgrade_settings = optional(object({
      max_surge                     = string
      drain_timeout_in_minutes      = optional(number)
      node_soak_duration_in_minutes = optional(number)
      undrainable_node_behavior     = optional(string)
    }))

    # Kubelet
    kubelet_config = optional(object({
      allowed_unsafe_sysctls    = optional(list(string), [])
      container_log_max_files   = optional(number)
      container_log_max_size_mb = optional(number)
      cpu_cfs_quota_enabled     = optional(bool)
      cpu_cfs_quota_period      = optional(string)
      cpu_manager_policy        = optional(string)
      image_gc_high_threshold   = optional(number)
      image_gc_low_threshold    = optional(number)
      pod_max_pid               = optional(number)
      topology_manager_policy   = optional(string)
    }))

    linux_os_config = optional(object({
      swap_file_size_mb            = optional(number)
      transparent_huge_page        = optional(string)
      transparent_huge_page_defrag = optional(string)

      sysctl_config = optional(object({
        fs_aio_max_nr               = optional(number)
        fs_file_max                 = optional(number)
        fs_inotify_max_user_watches = optional(number)
        fs_nr_open                  = optional(number)

        net_core_netdev_max_backlog = optional(number)
        net_core_rmem_max           = optional(number)
        net_core_somaxconn          = optional(number)
        net_core_wmem_max           = optional(number)

        net_ipv4_tcp_fin_timeout      = optional(number)
        net_ipv4_tcp_keepalive_intvl  = optional(number)
        net_ipv4_tcp_keepalive_probes = optional(number)
        net_ipv4_tcp_keepalive_time   = optional(number)
        net_ipv4_tcp_max_syn_backlog  = optional(number)

        vm_max_map_count      = optional(number)
        vm_swappiness         = optional(number)
        vm_vfs_cache_pressure = optional(number)
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

  # ------------------------------------------------------------
  # Validation (same rule as Kubernetes Cluster)
  # ------------------------------------------------------------
  validation {
    condition = alltrue(flatten([
      for l in values(var.kubernetes_node_pools) : [
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
    error_message = "Each Kubernetes Cluster must include non-empty tag values for all mandatory tags."
  }
}

