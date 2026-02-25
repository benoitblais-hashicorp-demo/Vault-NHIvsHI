# Read a secret from a KV v2 secrets engine in HCP Vault
# Note: the data source is deprecated in favour of ephemeral "vault_kv_secret_v2", but
# ephemeral values are suppressed in local-exec output and cannot be used in root module
# outputs. The data source with nonsensitive() is the only way to display the value.
data "vault_kv_secret_v2" "secret" {
  mount = var.kv_mount
  name  = var.secret_path
}
