# Vault Non-Human vs Human Identity Demo – KV v2 Secret Reader

This configuration provides a focused, runnable demonstration of how both **Non-Human Identity (NHI)** and **Human Identity (HI)** can read a secret from a KV v2 secrets engine in an HCP Vault Dedicated cluster.

It is intended as a companion to the [HCPVault-NHIvsHI](https://github.com/benoitblais-hashicorp-demo/HCPVault-NHIvsHI) and illustrates the contrast between the two identity types from a consumer perspective:

## What This Demo Demonstrates

### Non-Human Identity (NHI)

A single Vault entity represents the application workload. Two completely different
authentication methods resolve to that same entity, demonstrating that the identity is consistent
regardless of the platform executing the workload:

- **HCP Terraform** — The workspace uses dynamic provider credentials. HCP Terraform automatically
  generates and injects a short-lived JWT token into each run, which is exchanged for a Vault token.
  No static secret is stored anywhere.
- **GitHub Actions** — The workflow requests a short-lived OIDC token from GitHub and exchanges it
  for a Vault token using the JWT auth method. No static secret is stored anywhere.

### Human Identity (HI)

A human operator can authenticate to Vault and read the secret through multiple methods:

- **Vault UI** — The operator logs in directly through the Vault web interface using username/password
  (userpass auth method) and browses to the secret path.
- **GitHub Personal Access Token (CLI or Workflow)** — The operator authenticates using a GitHub PAT
  via Vault's GitHub auth method, either from a local terminal (`vault login -method=github`) or from
  a GitHub Actions workflow, and reads the secret value.

### Key Contrast

NHI credentials are short-lived, cryptographically bound to a platform context, and never held by a
human. HI credentials are static secrets that must be stored, remembered, rotated, and protected
manually. Both resolve to distinct Vault entities, making the difference immediately visible in the
Vault UI under **Access → Entities**.

## Demo Components

1. **Terraform Configuration Files** (NHI — HCP Terraform dynamic credentials):
   - **main.tf**: `data "vault_kv_secret_v2"` data source that reads the target KV v2 secret.
   - **variables.tf**: Input variables for the KV v2 mount path and secret path.
   - **outputs.tf**: Exports the retrieved secret data wrapped in `nonsensitive()` so it is
     displayed in plaintext during `terraform apply` (demo only).
   - **providers.tf**: Vault provider configuration.
   - **versions.tf**: Terraform and provider version constraints.

2. **GitHub Actions Workflow** (`.github/workflows/vault-read-secret-nhi.yml`) (NHI — GitHub OIDC JWT):
   - Triggered manually via `workflow_dispatch`.
   - All connection and authentication parameters are supplied as workflow inputs.
   - Uses direct `curl` calls to authenticate via GitHub OIDC JWT and retrieve the secret — intentionally
     bypasses `vault-action` auto-masking so the secret value is displayed in plaintext in the workflow log.
   - The OIDC token and Vault token are masked with `::add-mask::`; the secret payload is never registered
     as a secret. All key/value pairs are extracted with `jq` and printed individually as `key = value`.

3. **Human Identity Methods** (HI — no Terraform configuration required):
   - **Vault UI** — The operator logs in via the Vault web interface using the userpass auth method
     and reads the secret by browsing to its path.
   - **GitHub PAT (CLI)** — The operator runs `vault login -method=github token=<PAT>` from a local
     terminal and reads the secret with `vault kv get`.
   - **GitHub PAT (Workflow)** (`.github/workflows/vault-read-secret-hi.yml`) — A GitHub Actions
     workflow authenticates using a PAT stored as the repository secret `VAULT_GITHUB_TOKEN` via
     Vault's GitHub auth method using direct `curl` calls. The PAT and Vault token are masked;
     all key/value pairs are printed individually as `key = value` in the workflow log.

## Permissions

### Vault (hashicorp/vault)

- Requires read capability on the target KV v2 secret path (`<kv_mount>/data/<secret_path>`).
- No write, delete, or administrative permissions are required by this configuration.

## Authentication

Authentication to Vault can be configured using one of the following methods:

### HCP Terraform Dynamic Credentials (NHI — Recommended)

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

### GitHub Actions JWT (NHI — curl)

The workflow uses direct `curl` calls instead of `vault-action` to avoid automatic secret masking.
The GitHub Actions runner requests a short-lived OIDC token from GitHub, exchanges it for a Vault
token via the JWT auth method, then reads the KV v2 secret. The OIDC token and Vault token are
masked with `::add-mask::`, but the secret payload is never registered as a masked value, so it
prints in plaintext in the workflow log. No static secret is stored anywhere. Configure using
workflow inputs:

- `vault_address`: HCP Vault cluster URL.
- `vault_namespace`: Vault namespace (default: `admin/nhivshi-demo`).
- `auth_path`: Mount path of the JWT auth method (default: `github`).
- `vault_role`: Vault role used for authentication (default: `github-actions`).
- `jwt_audience`: Audience claim on the OIDC token — must match `bound_audiences` in the Vault JWT
  role (default: `https://vault.hashicorp.cloud`).
- `kv_mount`: KV v2 mount path (default: `secret`).
- `secret_path`: Path to the secret within the KV v2 mount (default: `demo/nhi-credentials`).

Documentation:

- [Vault JWT Auth Method](https://developer.hashicorp.com/vault/docs/auth/jwt)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

### GitHub Personal Access Token (HI — curl)

The HI workflow authenticates using a GitHub PAT stored as the repository secret `VAULT_GITHUB_TOKEN`
via Vault's GitHub auth method using direct `curl` calls, bypassing `vault-action` auto-masking so
secret values are displayed in plaintext. The PAT is a static credential — it must be stored,
rotated, and protected manually. The PAT and Vault token are masked with `::add-mask::`; the secret
payload is never registered as a masked value, so all key/value pairs print as `key = value`.
Configure using workflow inputs:

- `vault_address`: HCP Vault cluster URL.
- `vault_namespace`: Vault namespace (default: `admin`).
- `auth_path`: Mount path of the GitHub auth method (default: `github-hi`).
- `kv_mount`: KV v2 mount path (default: `secret`).
- `secret_path`: Path to the secret within the KV v2 mount.

Documentation:

- [Vault GitHub Auth Method](https://developer.hashicorp.com/vault/docs/auth/github)

### Static Token (Local / Manual Terraform Runs)

When running Terraform locally outside HCP Terraform, supply credentials via environment variables —
never hardcode them in `.tfvars` files:

- `VAULT_ADDR`: Full URL of the HCP Vault cluster, e.g. `https://<id>.vault.hashicorp.cloud:8200`.
- `VAULT_TOKEN`: A valid Vault token with read access to the target secret path.
- `VAULT_NAMESPACE`: Target namespace, e.g. `admin` for HCP Vault Dedicated.

## Features

- **KV v2 secret read** — Retrieves a versioned secret from any KV v2 mount at a user-supplied path.
- **Dual identity demonstration** — Shows NHI (HCP Terraform dynamic credentials and GitHub Actions OIDC JWT) and HI (userpass via Vault UI and GitHub PAT via CLI or workflow) reading the same KV v2 secret through distinct authentication flows.
- **Same NHI entity, two platforms** — Both HCP Terraform and GitHub Actions resolve to the same Vault entity (`nhi-demo-app`), demonstrating platform-agnostic identity.
- **Fully parameterized** — All connection and path details are supplied via input variables or workflow inputs; no code changes are required to target a different secret or cluster.
- **Intentional plaintext output** — Both GitHub Actions workflows use direct `curl` calls instead
  of `vault-action` so the secret payload is never auto-masked. The PAT/OIDC token and Vault token
  are masked with `::add-mask::`; all key/value pairs are extracted with `jq to_entries[]` and
  printed individually as `key = value` in the workflow log. In Terraform, `nonsensitive()` is used
  to display the secret during `terraform apply` (demo only); the secret is not marked sensitive in
  state by design for this demo.
- **Least-privilege ready** — The minimal Vault policy required is documented; the configuration does not require administrative permissions.

## Demo Value Proposition

- ✅ Illustrates the fundamental difference between NHI (short-lived, cryptographically bound, zero static secrets) and HI (static credentials that must be stored, rotated, and protected manually).
- ✅ Demonstrates how the same Vault entity (`nhi-demo-app`) is used by two completely different NHI platforms (HCP Terraform and GitHub Actions), making cross-platform identity consolidation visible in the Vault UI.
- ✅ Shows HI access to the same secret through two distinct human authentication methods (userpass UI login and GitHub PAT), both resolving to the `hi-demo-operator` entity.
- ✅ Provides a fully parameterized, repeatable configuration that requires no code changes to target a different secret or cluster.
- ✅ Uses `nonsensitive()` in Terraform outputs to display the secret value in plaintext during\n  `terraform apply`, making the demo immediately visible without requiring additional commands.
