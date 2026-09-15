---
title: CLI Configuration
type: docs
weight: 1
---

The DCM CLI (`dcm`) connects to the DCM control plane to manage resources. It
can be configured through command-line flags, environment variables, or a
configuration file.

For installation instructions, see
[Setting Up the CLI](../../getting-started/local-setup/#setting-up-the-cli).

## Configuration File

The CLI reads its configuration from `~/.dcm/config.yaml` by default. Here is an
example with all available fields:

```yaml
control-plane-url: http://localhost:8080
output-format: table
timeout: 30
tls-ca-cert: ""
tls-client-cert: ""
tls-client-key: ""
tls-skip-verify: false
issuer-url: ""
```

When the control plane requires authentication, set `issuer-url` or use
`dcm login` (see [Authentication](../getting-started/authentication/)).

## Configuration Priority

Settings are resolved in the following order (highest priority first):

1. Command-line flags
2. Environment variables (prefixed with `DCM_`)
3. Configuration file
4. Built-in defaults

## Global Flags

The following flags are available on all commands:

| Flag                  | Short | Default                 | Description                             |
| --------------------- | ----- | ----------------------- | --------------------------------------- |
| `--control-plane-url` |       | `http://localhost:8080` | URL of the DCM control plane            |
| `--output`            | `-o`  | `table`                 | Output format (`table`, `json`, `yaml`) |
| `--timeout`           |       | `30`                    | Request timeout in seconds              |
| `--config`            |       | `~/.dcm/config.yaml`    | Path to configuration file              |
| `--issuer-url`        |       | _(empty)_               | OIDC issuer URL for authentication      |
| `--token`             |       | _(empty)_               | Bearer token (skips interactive login)  |

## Authentication

When the control plane has authentication enabled, the CLI must send a JWT
bearer token on each request. Use one of the following approaches:

### Interactive login

Run `dcm login` after setting the issuer URL. The command runs the OIDC device
authorization flow in your browser and stores tokens locally.

```bash
dcm login --issuer-url http://keycloak:8080/realms/dcm \
  --control-plane-url http://localhost:8080
```

On success, `issuer-url` is saved in the config file. Use `dcm logout` to revoke
stored refresh tokens and clear credentials.

### Static token

For scripts and CI, pass a bearer access token without using the device flow:

| Flag / variable | Description                                 |
| --------------- | ------------------------------------------- |
| `--token`       | Bearer access token for this invocation     |
| `DCM_TOKEN`     | Same as `--token`, via environment variable |

When `--token` or `DCM_TOKEN` is set, the CLI does not read the token store.

### Auth-related settings

| Flag / variable  | Config key   | Description                                               |
| ---------------- | ------------ | --------------------------------------------------------- |
| `--issuer-url`   | `issuer-url` | OIDC issuer URL (required for `dcm login` / `dcm logout`) |
| `DCM_ISSUER_URL` | `issuer-url` | Environment override for issuer URL                       |

If `issuer-url` is set (and no static token is configured), the CLI loads tokens
from the OS keyring or `~/.dcm/tokens.json` and refreshes access tokens before
they expire.

Full workflows, control-plane settings, and troubleshooting are in
[Authentication](../getting-started/authentication/).

## TLS Configuration

To connect to a TLS-secured control plane, use the following flags:

| Flag                | Description                                                        |
| ------------------- | ------------------------------------------------------------------ |
| `--tls-ca-cert`     | Path to CA certificate file for TLS verification                   |
| `--tls-client-cert` | Path to client certificate file for mutual TLS                     |
| `--tls-client-key`  | Path to client private key file for mutual TLS                     |
| `--tls-skip-verify` | Skip TLS certificate verification (not recommended for production) |

## Output Formats

All commands support three output formats via the `-o` flag:

- **`table`** (default) — Human-readable tabular output.
- **`json`** — Structured JSON output, useful for scripting and automation.
- **`yaml`** — YAML output.

For example, to list providers as JSON:

```bash
dcm sp provider list -o json
```

## Shell Completion

Generate shell completion scripts with the `dcm completion` command:

```bash
# Bash
source <(dcm completion bash)

# Zsh
source <(dcm completion zsh)

# Fish
dcm completion fish | source

# PowerShell
dcm completion powershell | Out-String | Invoke-Expression
```

To make completion persistent, add the appropriate command to your shell profile
(e.g., `~/.bashrc`, `~/.zshrc`).
