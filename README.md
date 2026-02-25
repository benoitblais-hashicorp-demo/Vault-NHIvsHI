<!-- BEGIN_TF_DOCS -->
# Vault Non-Human vs Human Identity Demo – KV v2 Secret Reader

This configuration provides a focused, runnable demonstration of how both **Non-Human Identity (NHI)** and **Human Identity (HI)** can read a secret from a KV v2 secrets engine in an HCP Vault Dedicated cluster.

It is intended as a companion to the [HCPVault-NHIvsHI](https://github.com/benoitblais-hashicorp-demo/HCPVault-NHIvsHI) and illustrates the contrast between the two identity types from a consumer perspective:

- **NHI** — A GitHub Actions workflow requests a short-lived OIDC token and exchanges it for a Vault token using the JWT auth method. No static secret is ever stored.
- **HI** — Terraform authenticates using a static Vault token supplied via an environment variable, representing a human operator's credentials.

## What This Demo Demonstrates

- How a **non-human identity** (GitHub Actions) reads a KV v2 secret using short-lived, OIDC-based credentials via `vault-action`.
- How a **human identity** reads the same KV v2 secret using Terraform with a static Vault token supplied through environment variables.
- The fundamental difference in credential lifecycle: NHI tokens are ephemeral and context-bound; HI tokens are static and must be managed, rotated, and protected manually.

## Demo Components

1. **Terraform Configuration Files**:
   - **main.tf**: `vault_kv_secret_v2` data source that reads the target secret.
   - **variables.tf**: Input variables for the KV v2 mount path and secret path.
   - **outputs.tf**: Exports the retrieved secret data (sensitive) and its metadata.
   - **providers.tf**: Vault provider configuration.
   - **versions.tf**: Terraform and provider version constraints.

2. **GitHub Actions Workflow** (`.github/workflows/vault-read-secret.yml`):
   - Triggered manually via `workflow_dispatch`.
   - All connection and authentication parameters are supplied as workflow inputs.
   - Uses `hashicorp/vault-action` to authenticate via JWT and retrieve the secret.
   - Masks the secret value in logs while still demonstrating successful retrieval.

## Permissions

### Vault (hashicorp/vault)

- Requires read capability on the target KV v2 secret path (`<kv_mount>/data/<secret_path>`).
- No write, delete, or administrative permissions are required by this configuration.

## Authentication

Authentication to Vault can be configured using one of the following methods:

### Static Token (Human Identity / Terraform)

Supply credentials via environment variables — never hardcode them in `.tfvars` files:

- `VAULT_ADDR`: Full URL of the HCP Vault cluster, e.g. `https://<id>.vault.hashicorp.cloud:8200`.
- `VAULT_TOKEN`: A valid Vault token with read access to the target secret path.
- `VAULT_NAMESPACE`: Target namespace, e.g. `admin` for HCP Vault Dedicated.

### GitHub Actions JWT (Non-Human Identity / vault-action)

The workflow uses `hashicorp/vault-action` with OIDC-based authentication. The GitHub Actions runner
requests a short-lived OIDC token from GitHub and exchanges it for a Vault token. No static secret
is stored anywhere in the repository or runner environment. Configure using workflow inputs:

- `vault_address`: HCP Vault cluster URL.
- `vault_namespace`: Vault namespace (default: `admin`).
- `auth_method`: Vault auth method (default: `jwt`).
- `auth_path`: Mount path of the auth method (default: `github`).
- `vault_role`: Vault role used for authentication (default: `github-actions`).
- `kv_mount`: KV v2 mount path (default: `secret`).
- `secret_path`: Path to the secret within the KV v2 mount.
- `secret_key`: Key name within the secret to retrieve.

Documentation:

- [Vault JWT Auth Method](https://developer.hashicorp.com/vault/docs/auth/jwt)
- [hashicorp/vault-action](https://github.com/hashicorp/vault-action)

### HCP Terraform Dynamic Credentials (Recommended)

For enhanced security, use HCP Terraform's dynamic provider credentials to authenticate to Vault
without storing static tokens. HCP Terraform automatically generates and injects a short-lived JWT
token into each run. Set the following workspace environment variables:

- `TFC_VAULT_PROVIDER_AUTH`: Set to `true` to enable dynamic credentials.
- `TFC_VAULT_ADDR`: Set to your HCP Vault Dedicated cluster address (e.g., `https://<id>.vault.hashicorp.cloud:8200`).
- `TFC_VAULT_NAMESPACE`: Set to the target namespace (e.g., `admin`).
- `TFC_VAULT_AUTH_PATH`: Mount path of the JWT auth method configured for HCP Terraform (e.g., `hcp-terraform`).
- `TFC_VAULT_RUN_ROLE`: Vault JWT role name used for authentication (e.g., `hcp-terraform-workspace`).

Documentation:

- [HCP Terraform Dynamic Credentials](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials)
- [Vault JWT Auth Method](https://developer.hashicorp.com/vault/docs/auth/jwt)

## Features

- **KV v2 secret read** — Retrieves a versioned secret from any KV v2 mount at a user-supplied path.
- **Dual identity demonstration** — Shows NHI (GitHub Actions JWT) and HI (static Vault token) reading the same secret through different authentication flows.
- **Fully parameterized** — All connection and path details are supplied via input variables or workflow inputs; no code changes are required to target a different secret or cluster.
- **Secret masking** — Sensitive outputs are marked `sensitive = true` in Terraform; the GitHub Actions workflow applies `::add-mask::` before echoing the value.
- **Least-privilege ready** — The minimal Vault policy required is documented; the configuration does not require administrative permissions.

## Demo Value Proposition

- ✅ Illustrates the fundamental difference between NHI (short-lived, context-bound, zero static secrets) and HI (static credentials that must be managed, rotated, and protected).
- ✅ Demonstrates how the same KV v2 secret can be accessed by two completely different identity types using two different authentication flows.
- ✅ Provides a fully parameterized, repeatable configuration that requires no code changes to target a different secret or cluster.
- ✅ Shows how sensitive outputs are handled safely in both Terraform and GitHub Actions environments.

## Documentation

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.10.0)

- <a name="requirement_vault"></a> [vault](#requirement\_vault) (~> 5.7)

## Modules

No modules.

## Required Inputs

The following input variables are required:

### <a name="input_kv_mount"></a> [kv\_mount](#input\_kv\_mount)

Description: (Required) The path where the KV v2 secrets engine is mounted.

Type: `string`

### <a name="input_secret_path"></a> [secret\_path](#input\_secret\_path)

Description: (Required) The path to the secret within the KV v2 mount (e.g., 'myapp/config').

Type: `string`

## Optional Inputs

No optional inputs.

## Resources

No resources.

## Outputs

The following outputs are exported:

### <a name="output_secret_data"></a> [secret\_data](#output\_secret\_data)

Description: The key/value pairs retrieved from the KV v2 secret.

<!-- markdownlint-enable -->
## References

- [HCP Vault documentation](https://developer.hashicorp.com/hcp/docs/vault)
- [Terraform Vault provider – vault\_kv\_secret\_v2 data source](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/data-sources/kv_secret_v2)
- [Vault KV v2 secrets engine](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2)
- [Vault policy syntax](https://developer.hashicorp.com/vault/docs/concepts/policies)
<!-- END_TF_DOCS -->