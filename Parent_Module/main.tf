# Module for Resource Group

module "resource_groups" {
  source  = "../Child_Module/azurerm_resource_group"
  rg_name = var.rg_name_mod
}

# Module for Storage Account

module "storage_account" {
  depends_on       = [module.resource_groups]
  source           = "../Child_module/azurerm_storage_account"
  storage_accounts = var.storage_accounts_mod
}

# # Module for App Service Environments

module "azurerm_app_service_environment_v3" {
  depends_on                 = [module.resource_groups]
  source                     = "../Child_Module/azurerm_app_service_environment_v3"
  app_service_environment_v3 = var.app_service_environment_v3_mod
}

# Module for Service Plans

module "service_plan" {
  depends_on          = [module.resource_groups, module.azurerm_app_service_environment_v3, module.storage_account]
  source              = "../Child_Module/azurerm_service_plan"
  service_plans       = var.service_plans_mod
  service_env_app_ids = module.azurerm_app_service_environment_v3.service_app_env_ids

}

# # Module for Windows Function App

module "windows_function_app" {
  depends_on            = [module.resource_groups, module.service_plan, module.storage_account]
  source                = "../Child_Module/azurerm_windows_function_app"
  windows_function_apps = var.windows_function_apps_mod
  service_app_ids       = module.service_plan.service_app_ids

}

# Module for Windows Function App Slot

module "windows_function_app_slot" {
  depends_on                 = [module.resource_groups, module.windows_function_app, module.storage_account]
  source                     = "../Child_Module/azurerm_windows_function_app_slot"
  windows_function_app_slots = var.windows_function_app_slots_mod
  windows_function_ids       = module.windows_function_app.function_app_ids

}

# Module for Windows Web Apps

module "windows_web_app" {
  depends_on       = [module.resource_groups, module.service_plan]
  source           = "../Child_Module/azurerm_windows_web_app"
  windows_web_apps = var.windows_web_apps_mod
  service_app_ids  = module.service_plan.service_app_ids # we are taking value from the output block of service plan child module which is a map of service plan names to their IDs and it's used to associate the Windows Web Apps with the correct service plans.
}

# Module for Windows Web Apps Slots

module "windows_web_app_slot" {
  depends_on            = [module.resource_groups, module.windows_web_app]
  source                = "../Child_Module/azurerm_windows_web_app_slot"
  windows_web_app_slots = var.windows_web_app_slots_mod
  windows_web_app_ids   = module.windows_web_app.windows_web_app_ids

}

# Module for Linux Web Apps

module "linux_web_app" {
  depends_on      = [module.resource_groups, module.service_plan]
  source          = "../Child_Module/azurerm_linux_web_app"
  linux_web_apps  = var.linux_web_apps_mod
  service_app_ids = module.service_plan.service_app_ids

}

# Module for Linux Web Apps Slots

module "linux_web_app_slot" {
  depends_on          = [module.resource_groups, module.linux_web_app, module.storage_account]
  source              = "../Child_Module/azurerm_linux_web_app_slot"
  linux_web_app_slots = var.linux_web_app_slots_mod
  linux_web_app_ids   = module.linux_web_app.linux_web_app_ids

}

# # Module for Linux Function App

# here service_app_ids is a map of service plan names to their IDs and it's define in service plan child block in output block, which is used to associate the Linux Function Apps with the correct service plans.

module "linux_function_app" {
  depends_on          = [module.resource_groups, module.service_plan, module.storage_account]
  source              = "../Child_Module/azurerm_linux_function_app"
  linux_function_apps = var.linux_function_apps_mod
  service_app_ids     = module.service_plan.service_app_ids

}

# Module for Linux Function App Slot

module "linux_function_app_slot" {
  depends_on               = [module.resource_groups, module.linux_function_app, module.storage_account]
  source                   = "../Child_Module/azurerm_linux_function_app_slot"
  linux_function_app_slots = var.linux_function_app_slots_mod
  linux_function_ids       = module.linux_function_app.linux_function_app_ids

}

# Module for Key Vault Access Policy

# module "function_app_kv_access_policy" {
#   depends_on = [module.linux_function_app]
#   source = "../Child_Module/azurerm_key_vault_access_policy"
#   key_vault_access_policy = var.key_vault_access_policy_mod
#   function_app_principal_ids = module.linux_function_app.linux_function_app_principal_ids
# }

# Module for Key Vault

module "key_vault" {
  depends_on = [module.resource_groups]
  source     = "../Child_Module/azurerm_key_vault"
  key_vaults = var.key_vaults_mod
}

# # Module for Kubernetes Cluster

# module "kubernetes_cluster" {
#   depends_on = [module.resource_groups]
#   source     = "../Child_Module/azurerm_kubernetes_clusters"
#   kubernetes_clusters = var.kubernetes_clusters_mod
# }


# # Module for Kubernetes Cluster Node Pools

# module "kubernetes_cluster_node_pool" {
#   depends_on = [module.resource_groups, module.kubernetes_cluster]
#   source     = "../Child_Module/azurerm_kubernetes_cluster_node_pool"
#   kubernetes_node_pools = var.kubernetes_node_pools_mod
#   kubernetes_cluster_ids         = module.kubernetes_cluster.kubernetes_cluster_ids ## we are taking value from the output block of kubernetes child module which is a map of kubernetes cluster names to their IDs and it's used to associate the kubernetes node pool with the correct aks cluster.
# }


# Module for Network Interface

module "network_interface" {

  source = "../Child_Module/azurerm_network_interface"

  network_interfaces = var.network_interfaces_mod

}

# Module for Windows Virtual Machine and Network Interfaces

# Explain of this argument define in below module :network_interfaces_ids = module.network_interface.azure_network_interfaces_ids 
# if we look into this "network_interfaces_ids" is variable define into the child module and 
# in network interface child module main.tf file we have define the output block "azure_network_interfaces_ids" which is passing the value as id of network interface in this variable(network_interfaces_ids) 
# and this variable is used in same child module of the VM to associate the network interface with the virtual machine.

# module "windows_virtual_machine" {

#   depends_on = [ module.resource_groups ]

#   source = "../Child_Module/azurerm_windows_virtual_machine"

#   windows_virtual_machines = var.windows_virtual_machines_mod

#   # network_interfaces_windows = var.network_interfaces_mod

#   network_interfaces_ids = module.network_interface.azure_network_interfaces_ids  
# }

# Module for Linux Virtual Machine and Network Interfaces

module "linux_virtual_machine" {

  depends_on = [ module.resource_groups ]

  source = "../Child_Module/azurerm_linux_virtual_machine"

  linux_virtual_machines = var.linux_virtual_machines_mod

  # network_interfaces_linux = var.network_interfaces_mod

  network_interfaces_ids = module.network_interface.azure_network_interfaces_ids  
}