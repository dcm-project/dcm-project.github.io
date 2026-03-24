---
title: Create Small VM Catalog Item
type: docs
weight: 3
---

This guide walks you through creating a catalog item for a small virtual machine using the DCM CLI.

## Prerequisites

- DCM services running locally (see [Local Setup](../local-setup/))
- The `dcm` CLI installed and in your `PATH`

## Define the Catalog Item

For a detailed explanation of the catalog item schema, see the [Catalog Item Schema](../../enhancements/catalog-item-schema/) enhancement.

Create a file called `small-vm.yaml` with the following content:

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
      default: "rhel-10"
      validation_schema:
        type: string
        enum:
          - rhel-9
          - rhel-10
```

This defines a small VM catalog item with:
- **Metadata** — editable by users, for setting VM name and labels
- **2 vCPUs** — editable by users, between 1 and 4
- **2 GB memory** — fixed, not editable by users
- **Storage** — fixed, a single 20 GB boot disk
- **Guest OS** — editable by users, either `rhel-9` or `rhel-10`

## Create the Catalog Item

```bash
dcm catalog item create --from-file small-vm.yaml --id small-vm
```

Example output:

```
UID       DISPLAY NAME  SERVICE TYPE  CREATED
small-vm  Small VM      vm            2026-03-25T12:14:47.800832Z
```

## Verify the Catalog Item

```bash
dcm catalog item get small-vm
```

You can also view the full details in YAML format:

```bash
dcm catalog item get small-vm -o yaml
```
