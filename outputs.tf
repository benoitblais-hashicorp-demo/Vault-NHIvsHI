output "secret_data" {
  description = "The key/value pairs retrieved from the KV v2 secret."
  value       = data.vault_kv_secret_v2.secret.data
  sensitive   = false
}

# output "secret_metadata" {
#   description = "The metadata for the retrieved KV v2 secret (version, created_time, etc.)."
#   value       = data.vault_kv_secret_v2.secret.metadata
# }
