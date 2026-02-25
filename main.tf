# Read a secret from a KV v2 secrets engine in HCP Vault
ephemeral "vault_kv_secret_v2" "secret" {
  mount = var.kv_mount
  name  = var.secret_path
}
