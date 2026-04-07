---
title: Create Instance of Small VM Catalog Item
type: docs
weight: 5
---

This guide walks you through deploying a virtual machine on a KubeVirt service provider by creating a catalog item instance using the DCM CLI.

## Prerequisites

- DCM services running with the KubeVirt profile (see [Local Setup](../local-setup/))
- A KubeVirt service provider registered with DCM
- The `small-vm` catalog item created (see [Create Small VM Catalog Item](../create-small-vm-catalog-item/))
- The `dcm` CLI installed and in your `PATH`

## Define the Catalog Item Instance

Create a file called `my-vm.yaml` with the following content:

```yaml
api_version: v1alpha1
display_name: "My Dev VM"
spec:
  catalog_item_id: small-vm
  user_values:
    - path: metadata
      value:
        name: "small-vm"
        labels:
          env: "dev"
    - path: vcpu.count
      value: 1
```

This creates a VM instance based on the `small-vm` catalog item with:
- **Metadata** — sets the VM name to `small-vm` with a `dev` environment label
- **1 vCPU** — overriding the default of 2

## Create the Instance

```bash
dcm catalog instance create --from-file my-vm.yaml --id my-dev-vm
```

## Verify the Instance

```bash
dcm catalog instance get my-dev-vm
```

You can also view the full details in YAML format:

```bash
dcm catalog instance get my-dev-vm -o yaml
```

## Check the Resource Status

You can check the status of the underlying resource from the service provider resource manager:

```bash
dcm sp resource get my-dev-vm
```

Example output:

```
ID         PROVIDER                     STATUS      CREATED
my-dev-vm  kubevirt-service-provider  Scheduling  2026-03-25T13:01:46.496278Z
```
