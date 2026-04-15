---
title: CLI Configuration
type: docs
weight: 1
---

The DCM CLI (`dcm`) connects to the DCM API gateway to manage resources. It can be configured through command-line flags, environment variables, or a configuration file.

For installation instructions, see [Setting Up the CLI](../../getting-started/local-setup/#setting-up-the-cli).

## Configuration File

The CLI reads its configuration from `~/.dcm/config.yaml` by default. Here is an example with all available fields:

```yaml
api-gateway-url: http://localhost:9080
output-format: table
timeout: 30
tls-ca-cert: ""
tls-client-cert: ""
tls-client-key: ""
tls-skip-verify: false
```

## Configuration Priority

Settings are resolved in the following order (highest priority first):

1. Command-line flags
2. Environment variables (prefixed with `DCM_`)
3. Configuration file
4. Built-in defaults

## Global Flags

The following flags are available on all commands:

| Flag | Short | Default | Description |
|------|-------|---------|-------------|
| `--api-gateway-url` | | `http://localhost:9080` | URL of the DCM API gateway |
| `--output` | `-o` | `table` | Output format (`table`, `json`, `yaml`) |
| `--timeout` | | `30` | Request timeout in seconds |
| `--config` | | `~/.dcm/config.yaml` | Path to configuration file |

## TLS Configuration

To connect to a TLS-secured API gateway, use the following flags:

| Flag | Description |
|------|-------------|
| `--tls-ca-cert` | Path to CA certificate file for TLS verification |
| `--tls-client-cert` | Path to client certificate file for mutual TLS |
| `--tls-client-key` | Path to client private key file for mutual TLS |
| `--tls-skip-verify` | Skip TLS certificate verification (not recommended for production) |

## Output Formats

All commands support three output formats via the `-o` flag:

- **`table`** (default) — Human-readable tabular output.
- **`json`** — Structured JSON output, useful for scripting and automation.
- **`yaml`** — YAML output.

For example, to get the CLI version as JSON:

```bash
dcm version -o json
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

To make completion persistent, add the appropriate command to your shell profile (e.g., `~/.bashrc`, `~/.zshrc`).
