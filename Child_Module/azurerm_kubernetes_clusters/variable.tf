variable "kubernetes_clusters" {
  description = "Map of AKS clusters"

  type = map(object({
    name                = string
    location            = string
    resource_group_name = string

    dns_prefix                 = optional(string)
    dns_prefix_private_cluster = optional(string)

    kubernetes_version        = optional(string)
    automatic_upgrade_channel = optional(string)
    node_os_upgrade_channel   = optional(string)

    sku_tier     = optional(string)
    support_plan = optional(string)

    node_resource_group                 = optional(string)
    private_cluster_enabled             = optional(bool)
    private_dns_zone_id                 = optional(string)
    private_cluster_public_fqdn_enabled = optional(bool)

    role_based_access_control_enabled = optional(bool)
    local_account_disabled            = optional(bool)

    azure_policy_enabled       = optional(bool)
    oidc_issuer_enabled        = optional(bool)
    workload_identity_enabled  = optional(bool)
    run_command_enabled        = optional(bool)
    image_cleaner_enabled      = optional(bool)
    image_cleaner_interval_hours = optional(number)
    cost_analysis_enabled      = optional(bool)

    default_node_pool = object({
      name    = string
      vm_size = optional(string)

      node_count           = optional(number)
      auto_scaling_enabled = optional(bool)
      min_count            = optional(number)
      max_count            = optional(number)

      vnet_subnet_id = optional(string)
      pod_subnet_id  = optional(string)

      zones       = optional(list(string))
      node_labels = optional(map(string), {})

      max_pods = optional(number)

      os_disk_size_gb = optional(number)
      os_disk_type    = optional(string)
      os_sku          = optional(string)

      host_encryption_enabled      = optional(bool)
      node_public_ip_enabled       = optional(bool)
      only_critical_addons_enabled = optional(bool)

      temporary_name_for_rotation = optional(string)

      upgrade_settings = optional(object({
        max_surge                     = string
        drain_timeout_in_minutes      = optional(number)
        node_soak_duration_in_minutes = optional(number)
        undrainable_node_behavior     = optional(string)
      }))
    })

    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))

    service_principal = optional(object({
      client_id     = string
      client_secret = string
    }))

    network_profile = optional(object({
      network_plugin      = string
      network_plugin_mode = optional(string)
      network_policy      = optional(string)
      network_data_plane  = optional(string)

      dns_service_ip = optional(string)

      pod_cidr  = optional(string)
      pod_cidrs = optional(list(string))

      service_cidr  = optional(string)
      service_cidrs = optional(list(string))

      ip_versions       = optional(list(string))
      outbound_type     = optional(string)
      load_balancer_sku = optional(string)

      load_balancer_profile = optional(object({
        backend_pool_type           = optional(string)
        idle_timeout_in_minutes     = optional(number)
        managed_outbound_ip_count   = optional(number)
        managed_outbound_ipv6_count = optional(number)
        outbound_ip_address_ids     = optional(list(string))
        outbound_ip_prefix_ids      = optional(list(string))
        outbound_ports_allocated    = optional(number)
      }))

      nat_gateway_profile = optional(object({
        idle_timeout_in_minutes   = optional(number)
        managed_outbound_ip_count = optional(number)
      }))
    }))

    api_server_access_profile = optional(object({
      authorized_ip_ranges                = optional(set(string), [])
      subnet_id                           = optional(string)
      virtual_network_integration_enabled = optional(bool)
    }))

    azure_active_directory_role_based_access_control = optional(object({
      tenant_id              = optional(string)
      admin_group_object_ids = optional(list(string), [])
      azure_rbac_enabled     = optional(bool)
    }))

    key_vault_secrets_provider = optional(object({
      secret_rotation_enabled  = optional(bool)
      secret_rotation_interval = optional(string)
    }))

    monitor_metrics = optional(object({
      annotations_allowed = optional(string)
      labels_allowed      = optional(string)
    }))

    auto_scaler_profile = optional(object({
      balance_similar_node_groups      = optional(bool)
      expander                         = optional(string)
      max_graceful_termination_sec     = optional(string)
      max_node_provisioning_time       = optional(string)
      max_unready_nodes                = optional(number)
      max_unready_percentage           = optional(number)
      new_pod_scale_up_delay           = optional(string)
      scale_down_delay_after_add       = optional(string)
      scale_down_delay_after_delete    = optional(string)
      scale_down_delay_after_failure   = optional(string)
      scan_interval                    = optional(string)
      scale_down_unneeded              = optional(string)
      scale_down_unready               = optional(string)
      scale_down_utilization_threshold = optional(string)
      empty_bulk_delete_max            = optional(string)
      skip_nodes_with_local_storage    = optional(bool)
      skip_nodes_with_system_pods      = optional(bool)
    }))

    workload_autoscaler_profile = optional(object({
      keda_enabled                    = optional(bool)
      vertical_pod_autoscaler_enabled = optional(bool)
    }))

    storage_profile = optional(object({
      blob_driver_enabled         = optional(bool)
      disk_driver_enabled         = optional(bool)
      file_driver_enabled         = optional(bool)
      snapshot_controller_enabled = optional(bool)
    }))

    linux_profile = optional(object({
      admin_username = string

      ssh_key = object({
        key_data = string
      })
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
  # Validation (same rule as Windows)
  # ------------------------------------------------------------
  validation {
    condition = alltrue(flatten([
      for l in values(var.kubernetes_clusters) : [
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