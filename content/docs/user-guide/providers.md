---
title: Providers
type: docs
weight: 2
---

Providers are infrastructure endpoints registered by service provider instances. Each provider represents a backend system — such as a KubeVirt-enabled Kubernets cluster — that can host virtual machines or other resources managed through DCM.

Providers are **read-only** in the CLI. They are created automatically when a service provider instance connects to DCM and registers its available infrastructure.

## Listing Providers

Use `dcm sp provider list` to display all registered providers:

```bash
dcm sp provider list
```

Example output:

```
ID                                     NAME                  SERVICE TYPE   STATUS       HEALTH    CREATED
3f8a1b2c-4d5e-6f7a-8b9c-0d1e2f3a4b5c  kubevirt-cluster-01   vm             REGISTERED   HEALTHY   2026-01-15T08:30:00Z
a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d  kubevirt-cluster-02   vm             REGISTERED   HEALTHY   2026-02-20T14:45:00Z
```

### Filtering by Service Type

Use the `--type` flag to show only providers of a specific service type:

```bash
dcm sp provider list --type vm
```

### Pagination

For environments with many providers, use pagination flags to control the output:

- `--page-size` — Maximum number of providers to return per page (int32).
- `--page-token` — Token for retrieving the next page of results (returned in the previous response).

```bash
dcm sp provider list --page-size 10
```

## Getting Provider Details

Use `dcm sp provider get` to retrieve detailed information about a single provider:

```bash
dcm sp provider get 3f8a1b2c-4d5e-6f7a-8b9c-0d1e2f3a4b5c
```

To view the full details as JSON:

```bash
dcm sp provider get 3f8a1b2c-4d5e-6f7a-8b9c-0d1e2f3a4b5c -o json
```

Example JSON output:

```json
{
  "id": "3f8a1b2c-4d5e-6f7a-8b9c-0d1e2f3a4b5c",
  "name": "kubevirt-cluster-01",
  "service_type": "vm",
  "status": "REGISTERED",
  "health": "HEALTHY",
  "create_time": "2026-01-15T08:30:00Z"
}
```

## Provider Status and Health

Each provider exposes two key fields:

- **STATUS** — Reflects the provider's registration state within DCM. A status of `REGISTERED` means the provider has been successfully registered and is recognized by the system.
- **HEALTH** — Reflects the result of the provider's last health check. A health value of `HEALTHY` indicates that the provider is reachable and operating normally.

These fields are updated automatically as service provider instances report to DCM.

> **Note:** See [Register Another Provider](../../getting-started/register-another-provider/) for a walkthrough of adding a new provider.
