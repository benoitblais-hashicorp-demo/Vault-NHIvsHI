output "secret_data" {
  description = "The key/value pairs retrieved from the KV v2 secret."
  value       = nonsensitive(data.vault_kv_secret_v2.secret.data)
}
