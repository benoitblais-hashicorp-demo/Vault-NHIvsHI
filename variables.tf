variable "kv_mount" {
  type        = string
  description = "(Required) The path where the KV v2 secrets engine is mounted."
}

variable "secret_path" {
  type        = string
  description = "(Required) The path to the secret within the KV v2 mount (e.g., 'myapp/config')."
}
