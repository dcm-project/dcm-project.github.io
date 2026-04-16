---
title: Catalog Items
type: docs
weight: 4
---

Catalog items are reusable templates that define a deployable resource. Each catalog item references a [service type](../service-types/) and may specify whether a resource configuration is editable while setting a preset, a default value and/or a validation schema for the user values — for example, CPU, memory, and storage for a virtual machine.

## Creating a Catalog Item

To create a catalog item, define its configuration in a YAML or JSON file and pass it to the CLI:

```bash
dcm catalog item create --from-file item.yaml
```

To specify a custom identifier instead of letting DCM generate one:

```bash
dcm catalog item create --from-file item.yaml --id my-small-vm
```

### Example YAML

Below is a complete catalog item definition for a small virtual machine:

```yaml
api_version: v1alpha1
display_name: "Small VM"
spec:
  service_type: vm
  fields:
    - path: metadata
      editable: true
    - path: vcpu.count
      display_name: "CPU Count"
      editable: true
      default: 2
      validation_schema:
        type: integer
        minimum: 1
        maximum: 4
    - path: memory.size
      display_name: "Memory (GB)"
      editable: false
      default: "2GB"
    - path: storage.disks
      display_name: "Storage (GB)"
      editable: false
      default:
        - name: boot
          capacity: "20GB"
      validation_schema:
        type: array
    - path: guest_os.type
      display_name: "Guest OS"
      editable: true
      validation_schema:
        type: string
        enum:
          - fedora
          - centos
          - ubuntu
```

### Key Sections

| Section | Purpose |
|---------|---------|
| `api_version` | Ties the catalog item to a specific schema version (e.g., `v1alpha1`). |
| `display_name` | A human-readable name shown in listings and the UI. |
| `spec.service_type` | Corresponding service type |
| `spec.fields` | List of fields with const or user values |
| `spec.fields[].path` | Path of the field within the `service_type` specification |
| `spec.fields[].display_name` |  A human-readable name shown in listings and the UI |
| `spec.fields[].editable` | Specify whether the user may edit the value |
| `spec.fields[].default` | Default value for the field. When `editable` is `false` this becomes the actual value |
| `spec.fields[].validation_schema` | JSON Schema rules to validate input. See: https://json-schema.org/ |

### Verifying the Catalog Item

After creating a catalog item, confirm it was registered successfully:

```bash
dcm catalog item get CATALOG_ITEM_ID
```

## Listing Catalog Items

Use `dcm catalog item list` to view all catalog items:

```bash
dcm catalog item list
```

Example output:

```
UID                                    DISPLAY NAME   SERVICE TYPE   CREATED
small-vm                               Small VM       vm             2026-03-10T08:15:00Z
a7c2d9e4-b1f3-4567-89ab-cdef01234567   Large VM       vm             2026-03-12T14:30:00Z
web-server                             Web Server     container      2026-03-15T09:45:00Z
```

### Filtering by Service Type

To show only catalog items for a specific service type:

```bash
dcm catalog item list --service-type "vm"
```

### Pagination

For environments with many catalog items, use pagination flags:

```bash
dcm catalog item list --page-size 10
```

To fetch the next page, pass the token returned by the previous response:

```bash
dcm catalog item list --page-size 10 --page-token "eyJvZmZzZXQiOjEwfQ=="
```

## Getting Catalog Item Details

Use `dcm catalog item get` to retrieve the full definition of a catalog item:

```bash
dcm catalog item get f4a8b3c1-d2e5-6789-abcd-ef0123456789
```

To view the output in JSON format:

```bash
dcm catalog item get f4a8b3c1-d2e5-6789-abcd-ef0123456789 -o json
```

Example JSON output:

```json
{
  "api_version": "v1alpha1",
  "create_time": "2026-04-15T18:06:02.434302Z",
  "display_name": "Small VM",
  "path": "catalog-items/small-vm",
  "spec": {
    "fields": [
      {
        "editable": true,
        "path": "metadata"
      },
      {
        "default": 2,
        "display_name": "CPU Count",
        "editable": true,
        "path": "vcpu.count",
        "validation_schema": {
          "maximum": 4,
          "minimum": 1,
          "type": "integer"
        }
      },
      {
        "default": "2GB",
        "display_name": "Memory (GB)",
        "path": "memory.size"
      },
      {
        "default": [
          {
            "capacity": "20GB",
            "name": "boot"
          }
        ],
        "display_name": "Storage (GB)",
        "path": "storage.disks",
        "validation_schema": {
          "type": "array"
        }
      },
      {
        "default": "fedora",
        "display_name": "Guest OS",
        "editable": true,
        "path": "guest_os.type",
        "validation_schema": {
          "enum": [
            "fedora",
            "centos",
            "ubuntu"
          ],
          "type": "string"
        }
      }
    ],
    "service_type": "vm"
  },
  "uid": "small-vm",
  "update_time": "2026-04-15T18:06:02.434302Z"
}
```

## Deleting a Catalog Item

To remove a catalog item:

```bash
dcm catalog item delete f4a8b3c1-d2e5-6789-abcd-ef0123456789
```

> **Note:** Deleting a catalog item with instances that were already created from it will fail. Remove all existing instances before deleting the item.

---

For a step-by-step walkthrough, see [Create Small VM Catalog Item](../../getting-started/create-small-vm-catalog-item/).
