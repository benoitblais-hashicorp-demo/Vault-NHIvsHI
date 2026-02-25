# Ephemeral values cannot be used in root module outputs (ephemeral outputs are not allowed).
# The secret is displayed during apply via the terraform_data provisioner in main.tf.

# output "secret_metadata" {
#   description = "The metadata for the retrieved KV v2 secret (version, created_time, etc.)."
#   value       = data.vault_kv_secret_v2.secret.metadata
# }
