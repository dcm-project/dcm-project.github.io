---
title: Catalog Item Instances
type: docs
weight: 6
---

Catalog item instances represent deployed resources created from a [catalog item](../catalog-items/). When you create an instance, DCM evaluates policies to validate the input and select a provider, then provisions the resource on that provider. Instances can override fields allowed by the catalog item's `fields` via `user_values`.

## Creating an Instance

To create an instance, define its configuration in a YAML or JSON file and pass it to the CLI:

```bash
dcm catalog instance create --from-file instance.yaml
```

To specify a custom identifier instead of letting DCM generate one:

```bash
dcm catalog instance create --from-file instance.yaml --id my-instance
```

### Example YAML

Below is a complete instance definition that creates a virtual machine from an existing catalog item, overriding the vCPU count, setting the O/S type and adding name and labels to the metadata:

```yaml
api_version: v1alpha1
display_name: "My Dev VM"
spec:
  catalog_item_id: small-vm
  user_values:
    - path: metadata
      value:
        name: "demo"
        labels:
          env: "dev"
    - path: vcpu.count
      value: 1
    - path: guest_os.type
      value: fedora
```

### Key Fields

| Field | Purpose |
|-------|---------|
| `display_name` | An optional human-readable name shown in listings and the UI. |
| `spec.catalog_item_id` | References the UID of an existing catalog item to deploy from. |
| `spec.user_values` | Sets of overrides for fields allowed by the catalog item's `fields` array. Only fields with `editable_fields: true` can be customized here. |
| `spec.user_values[].path` | Path corresponding to the `path` key in the `catalog_item`'s `fields` item |

> **Note:** Any values provided in `user_values` that are not permitted by the catalog item's `validation_schema` will be rejected. Check the catalog item's `editable_fields` to see which fields you can override.

### Verifying the Instance

After creating an instance, confirm it was provisioned successfully:

```bash
dcm catalog instance get INSTANCE_ID
```

## Listing Instances

Use `dcm catalog instance list` to view all instances:

```bash
dcm catalog instance list
```

Example output:

```
UID                                     DISPLAY NAME     CATALOG ITEM                            RESOURCE ID                             CREATED
b2d4f6a8-1c3e-5678-9abc-def012345678   My VM Instance   f4a8b3c1-d2e5-6789-abcd-ef0123456789   r-7a9c2e41-b3d5-4f68-80a1-e2c4d6f8a0b2   2026-04-01T10:30:00Z
c5e7a9b1-2d4f-6789-0abc-123456789def   Dev Database     a7c2d9e4-b1f3-4567-89ab-cdef01234567   r-3b5d7f90-c1e3-4a26-98b0-d4f6a8c2e0a1   2026-04-03T14:15:00Z
```

> **Note:** The Resource ID refers to the ID of the corresponding [Service Type Resource](../service-provider-resources).

### Filtering by Catalog Item

To show only instances created from a specific catalog item:

```bash
dcm catalog instance list --catalog-item-id f4a8b3c1-d2e5-6789-abcd-ef0123456789
```

### Pagination

For environments with many instances, use pagination flags:

```bash
dcm catalog instance list --page-size 10
```

To fetch the next page, pass the token returned by the previous response:

```bash
dcm catalog instance list --page-size 10 --page-token "eyJvZmZzZXQiOjEwfQ=="
```

## Getting Instance Details

Use `dcm catalog instance get` to retrieve the full details of an instance:

```bash
dcm catalog instance get b2d4f6a8-1c3e-5678-9abc-def012345678
```

To view the output in JSON format:

```bash
dcm catalog instance get b2d4f6a8-1c3e-5678-9abc-def012345678 -o json
```

Example JSON output:

```json
{
  "api_version": "v1alpha1",
  "create_time": "2026-04-15T18:38:19.968231Z",
  "display_name": "My Dev VM",
  "path": "catalog-item-instances/7f4aca9b-5a2f-46aa-94c4-cd8309a86bf5",
  "resource_id": "d828d392-47ee-468b-ac61-b71927049efc",
  "spec": {
    "catalog_item_id": "small-vm",
    "user_values": [
      {
        "path": "metadata",
        "value": {
          "labels": {
            "env": "dev"
          },
          "name": "demo"
        }
      },
      {
        "path": "vcpu.count",
        "value": 1
      },
      {
        "path": "guest_os.type",
        "value": "fedora"
      }
    ]
  },
  "uid": "7f4aca9b-5a2f-46aa-94c4-cd8309a86bf5",
  "update_time": "2026-04-15T18:38:19.968231Z"
}
```

## Rehydrating an Instance

Use `dcm catalog instance rehydrate` to re-trigger the provisioning flow for an existing instance:

```bash
dcm catalog instance rehydrate b2d4f6a8-1c3e-5678-9abc-def012345678
```

Rehydration refreshes an instance by running the provisioning process again. This is useful when:

- A provider has recovered from a failure and the resource needs to be re-provisioned.
- The underlying resource needs to be recreated or updated.
- Placement policies have changed and you want the instance to be re-evaluated against the current configuration.

> **Note:** Rehydration will first provision the new resource before trying to delete the old one. Make sure to update and references (e.g. DNS) if needed

## Deleting an Instance

To remove an instance:

```bash
dcm catalog instance delete b2d4f6a8-1c3e-5678-9abc-def012345678
```

> **Note:** Deleting an instance also triggers cleanup of the underlying resource on the provider. The provisioned resource will be removed as part of the deletion process.

---

For a step-by-step walkthrough, see [Create Instance of Small VM Catalog Item](../../getting-started/create-small-vm-instance/).
