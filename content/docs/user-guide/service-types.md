---
title: Service Types
type: docs
weight: 3
---

Service types define the kinds of services that DCM can manage. Each service type represents a specific resource category — for example, virtual machines or containers.

Service types define the schema that [catalog items](../catalog-items/) must conform to, ensuring that resources are created with valid configurations.

> **Note:** Currently, service types cannot be created or modified through the CLI. They are pre-registered by the Catalog Manager.

## Listing Service Types

Use `dcm catalog service-type list` to view all registered service types:

```bash
dcm catalog service-type list
```

Example output:

```
UID                  SERVICE TYPE         API VERSION  CREATED
cluster              cluster              v1alpha1     2026-04-15T17:34:21.225163Z
container            container            v1alpha1     2026-04-15T17:34:21.225003Z
three-tier-app-demo  three-tier-app-demo  v1alpha1     2026-04-15T17:34:21.224575Z
vm                   vm                   v1alpha1     2026-04-15T17:34:21.224901Z
```

The table columns are:

| Column | Description |
|--------|-------------|
| `UID` | Unique identifier for the service type |
| `SERVICE TYPE` | The type name, typically in a `group/Kind` format |
| `API VERSION` | Schema version of the service type |
| `CREATED` | Timestamp when the service type was registered |

### Pagination

For environments with many service types, use pagination flags to control the output:

```bash
dcm catalog service-type list --page-size 10
```

To fetch the next page, pass the token returned by the previous response:

```bash
dcm catalog service-type list --page-size 10 --page-token "eyJvZmZzZXQiOjEwfQ=="
```

## Getting Service Type Details

Use `dcm catalog service-type get` to retrieve details for a specific service type:

```bash
dcm catalog service-type get a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

To get the full details in JSON format:

```bash
dcm catalog service-type get a1b2c3d4-e5f6-7890-abcd-ef1234567890 -o json
```

Example JSON output:

```json
{
  "uid": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "service_type": "kubevirt.io/VirtualMachine",
  "api_version": "v1alpha1",
  "create_time": "2026-01-15T10:30:00Z"
}
```

## How Service Types Relate to Other Resources

Service types sit at the foundation of the DCM resource model:

- **Catalog items** reference a service type and must conform to its schema. See [Catalog Items](../catalog-items/).
- **Providers** register with a specific service type, indicating what kinds of resources they can host. See [Providers](../providers/).
- **Catalog item instances** are ultimately deployed according to the schema defined by the service type. See [Catalog Item Instances](../catalog-item-instances/).
