
variable "function_app_principal_ids" {
      type = map(string)
}

variable "key_vault_access_policy" {
  type = map(object({

    existing_func_app_name = string
    key_vault_name    = string
    key_vault_rg_name = string
    tenant_id         = string
    secret_permissions = optional(list(string))
    key_permissions = optional(list(string))
    certificate_permissions = optional(list(string))

  }))
}