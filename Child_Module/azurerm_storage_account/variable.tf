variable "storage_accounts" {
  description = <<-EOT
  Map of Storage Account configurations. Keys are arbitrary IDs; values describe each storage account.

  Notes & Constraints (summarized from Azure/Terraform docs):
  - name: lowercase alphanumeric; must be globally unique; changing forces new resource.
  - account_tier: Standard | Premium. (BlockBlobStorage/FileStorage => Premium only)
  - account_kind: BlobStorage | BlockBlobStorage | FileStorage | Storage | StorageV2 (default StorageV2).
  - replication: LRS | GRS | RAGRS | ZRS | GZRS | RAGZRS; some changes force recreation.
  - access_tier: Hot | Cool | Cold | Premium; only valid for BlobStorage, FileStorage, StorageV2.
  - is_hns_enabled/NFS/SFTP compatibility rules apply (see Azure docs).
  - queue_properties allowed only on Standard with kind Storage/StorageV2.
  - static_website only on StorageV2/BlockBlobStorage.
  - share_properties: Standard (Storage/StorageV2) or Premium (FileStorage).
  - Customer-managed key requires StorageV2 or Premium + UserAssigned identity.
  EOT

  type = map(object({
    # ---------------- Core (Required) ----------------
    name                     = string # (Required)
    resource_group_name      = string # (Required)
    location                 = string # (Required)
    account_tier             = string # (Required) Standard | Premium
    account_replication_type = string # (Required) LRS | GRS | RAGRS | ZRS | GZRS | RAGZRS
    tags = object({                   # As it's Optional argument as per the terraform registry but we consider as required
      owner           = string        # optional
      ApplicationName = string
      CreatedBy       = optional(string) #optional
      BusinessService = optional(string) #optional
      Environment     = string
      OpsTeam         = string
      Portfolio       = string
      PortfolioArea   = string
      RequestedBy     = string
      Vendor          = string
      ServiceType     = optional(string) # This tag is used to specify the type of service. We make it optional here to avoid forcing all storage accounts to have it, but we ignore it in lifecycle to prevent unnecessary diffs if it's added/removed.
      SolutionName    = optional(string) # This tag is used by the StartStopV2 solution. We make it optional here to avoid forcing all storage accounts to have it, but we ignore it in lifecycle to prevent unnecessary diffs if it's added/removed.
    })
    account_kind                    = optional(string)           # (Optional)
    is_hns_enabled                  = optional(bool, false)      # (Optional)
    nfsv3_enabled                   = optional(bool, false)      # (Optional)
    min_tls_version                 = optional(string, "TLS1_2") # (Optional) TLS1_0|TLS1_1|TLS1_2|TLS1_3
    public_network_access_enabled   = optional(bool, true)       # (Optional)
    allow_nested_items_to_be_public = optional(bool, true)       # (Optional)
    access_tier                     = optional(string)           # (Optional) Hot | Cool | Cold | Premium

    # ---------------- General (Optional) -------------

    provisioned_billing_model_version = optional(string)             # (Optional) e.g. "V2"
    cross_tenant_replication_enabled  = optional(bool, false)        # (Optional)
    edge_zone                         = optional(string)             # (Optional)
    https_traffic_only_enabled        = optional(bool, true)         # (Optional)
    shared_access_key_enabled         = optional(bool, true)         # (Optional)
    default_to_oauth_authentication   = optional(bool)               # (Optional)
    large_file_share_enabled          = optional(bool, false)        # (Optional)
    local_user_enabled                = optional(bool, true)         # (Optional)
    queue_encryption_key_type         = optional(string)             # (Optional) Service | Account
    table_encryption_key_type         = optional(string)             # (Optional) Service | Account
    infrastructure_encryption_enabled = optional(bool, false)        # (Optional)
    allowed_copy_scope                = optional(string)             # (Optional) AAD | PrivateLink
    sftp_enabled                      = optional(bool, false)        # (Optional; requires is_hns_enabled = true)
    dns_endpoint_type                 = optional(string, "Standard") # (Optional) Standard | AzureDnsZone
  }))

  # Condition to check wether the tags value is provided as per the policy
  validation {
    condition = alltrue(flatten([
      for w in values(var.storage_accounts) : [
        trimspace(w.tags.owner) != "",
        trimspace(w.tags.ApplicationName) != "",
        trimspace(w.tags.CreatedBy) != "",
        trimspace(w.tags.BusinessService) != "",
        trimspace(w.tags.Environment) != "",
        trimspace(w.tags.OpsTeam) != "",
        trimspace(w.tags.Portfolio) != "",
        trimspace(w.tags.PortfolioArea) != "",
        trimspace(w.tags.RequestedBy) != "",
        trimspace(w.tags.Vendor) != ""
      ]
    ]))
    error_message = "Each workload must include non-empty values for: owner, ApplicationName, CreatedBy, BusinessService, Environment, OpsTeam, Portfolio, PortfolioArea, RequestedBy, Vendor."
  }




}
