# Read a secret from a KV v2 secrets engine in HCP Vault
ephemeral "vault_kv_secret_v2" "secret" {
  mount = var.kv_mount
  name  = var.secret_path
}

# Display the secret to the screen during apply (demo only)
# Ephemeral values cannot be used in outputs but can be passed to provisioners
resource "terraform_data" "display_secret" {
  provisioner "local-exec" {
    command = "echo Secret data: $SECRET_DATA"

    environment = {
      SECRET_DATA = jsonencode(ephemeral.vault_kv_secret_v2.secret.data)
    }
  }
}
