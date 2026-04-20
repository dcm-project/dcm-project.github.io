---
title: Service Provider Resources
type: docs
weight: 7
---

Service provider resources are the actual infrastructure resources — such as virtual machines, containers, or other services — created on [providers](../providers/) when [catalog item instances](../catalog-item-instances/) are provisioned. For example, when you deploy a catalog item instance for a VM on a KubeVirt provider, the service provider manager creates a KubeVirt VirtualMachine resource. That underlying resource is the SP resource.

SP resources are managed entirely by the service provider manager and are **read-only** in the CLI. Each SP resource is linked to a specific catalog item instance and the provider where it was provisioned.

> **Note:** You cannot create, update, or delete SP resources directly. They are created and cleaned up automatically as part of the catalog item instance lifecycle.

## Listing Resources

Use `dcm sp resource list` to view all service provider resources:

```bash
dcm sp resource list
```

Example output:

```
ID                                       PROVIDER               STATUS   CREATED
r-7a9c2e41-b3d5-4f68-80a1-e2c4d6f8a0b2  kubevirt-provider-1    READY    2026-04-01T10:30:00Z
r-3b5d7f90-c1e3-4a26-98b0-d4f6a8c2e0a1  kubevirt-provider-2    READY    2026-04-03T14:15:00Z
r-9e1a3c5d-7f20-4b68-a0c2-e4d6f8b1a3c5  container-provider-1   PENDING  2026-04-10T09:00:00Z
```

### Filtering by Provider

To show only resources on a specific provider, use the `--provider` flag:

```bash
dcm sp resource list --provider kubevirt-provider-1
```

### Showing Deleted Resources

By default, deleted resources are hidden. Use `--show-deleted` to include them in the output. This adds a DELETION STATUS column:

```bash
dcm sp resource list --show-deleted
```

Example output:

```
ID                                       PROVIDER               STATUS   DELETION STATUS   CREATED
r-7a9c2e41-b3d5-4f68-80a1-e2c4d6f8a0b2  kubevirt-provider-1    READY                       2026-04-01T10:30:00Z
r-3b5d7f90-c1e3-4a26-98b0-d4f6a8c2e0a1  kubevirt-provider-2    READY     PENDING           2026-04-03T14:15:00Z
r-9e1a3c5d-7f20-4b68-a0c2-e4d6f8b1a3c5  container-provider-1   PENDING                     2026-04-10T09:00:00Z
```

### Pagination

For environments with many resources, use pagination flags to control the output:

```bash
dcm sp resource list --page-size 10
```

To fetch the next page, pass the token returned by the previous response:

```bash
dcm sp resource list --page-size 10 --page-token "eyJvZmZzZXQiOjEwfQ=="
```

## Getting Resource Details

Use `dcm sp resource get` to retrieve the full details of a single resource:

```bash
dcm sp resource get r-7a9c2e41-b3d5-4f68-80a1-e2c4d6f8a0b2
```

To view the output in JSON format:

```bash
dcm sp resource get r-7a9c2e41-b3d5-4f68-80a1-e2c4d6f8a0b2 -o json
```

Example JSON output:

```json
{
  "create_time": "2026-04-15T19:10:19.616508Z",
  "id": "e4deb2bc-6c61-44b6-9bc9-6a8e5b813c0d",
  "path": "service-type-instances/e4deb2bc-6c61-44b6-9bc9-6a8e5b813c0d",
  "provider_name": "kubevirt-main",
  "spec": {
    "access": {},
    "guest_os": {
      "type": "fedora"
    },
    "memory": {
      "size": "2GB"
    },
    "metadata": {
      "labels": {
        "env": "dev"
      },
      "name": "demo"
    },
    "service_type": "vm",
    "storage": {
      "disks": [
        {
          "capacity": "20GB",
          "name": "boot"
        }
      ]
    },
    "vcpu": {
      "count": 1
    }
  },
  "status": "Scheduling",
  "update_time": "2026-04-15T19:17:01.990818Z"
}
```

To include deletion details for a resource that may have been deleted:

```bash
dcm sp resource get r-3b5d7f90-c1e3-4a26-98b0-d4f6a8c2e0a1 --show-deleted
```

## Resource Lifecycle

SP resources follow the lifecycle of the catalog item instances they belong to:

1. **Creation** — When a catalog item instance is provisioned, the service provider manager automatically creates the corresponding SP resource on the selected provider.
2. **Active state** — The STATUS field reflects the current state of the resource on the provider (e.g., PENDING while being created, READY when fully provisioned).
3. **Rehydration** - When a catalog item instance is rehydrated, a new resource will be created and upon success, the old one will be scheduled for deletion.
4. **Deletion** — When a catalog item instance is deleted, the corresponding SP resource is cleaned up by the service provider manager.
5. **Viewing deleted resources** — Deleted resources are hidden by default but can still be viewed using the `--show-deleted` flag, which adds a DELETION STATUS column to the output.

> **Note:** Deleted items will show while they are scheduled for deletion. Once they are removed from the SP they will no longer exist

## Relationship to Catalog Item Instances

Each [catalog item instance](../catalog-item-instances/) results in one SP resource on the provider selected during placement. The `resource_id` field on a catalog item instance links directly to the corresponding SP resource's ID.

For example, if a catalog item instance has `resource_id: r-7a9c2e41-b3d5-4f68-80a1-e2c4d6f8a0b2`, you can inspect the underlying provider resource with:

```bash
dcm sp resource get r-7a9c2e41-b3d5-4f68-80a1-e2c4d6f8a0b2
```
