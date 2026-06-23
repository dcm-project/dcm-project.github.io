---
title: Architecture Overview
type: docs
weight: 1
---

DCM (Data Center Management) is a control plane for managing infrastructure
services across multiple providers. This page gives a high-level overview of how
the components fit together.

## Components

```mermaid
graph TD
    User["User (CLI / API)"]

    subgraph CP["Control Plane (:8080)"]
        CM["Catalog Manager"]
        PM["Policy Manager"]
        PLM["Placement Manager"]
        SPM["Service Provider Manager"]
    end

    subgraph Infrastructure
        PG["PostgreSQL"]
        NATS["NATS"]
    end

    subgraph Providers
        SP1["KubeVirt SP 1"]
        SP2["KubeVirt SP 2"]
    end

    User --> CP

    CM --> PG
    PM --> PG
    PLM --> PG
    SPM --> PG

    PLM --> PM
    PLM --> SPM
    CM --> PLM

    SPM --> NATS
    SP1 --> NATS
    SP2 --> NATS
    SP1 -->|self-register| SPM
    SP2 -->|self-register| SPM
```

## Component Responsibilities

| Component                    | Role                                                                                                                                    |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Control Plane**            | Single process that exposes all DCM APIs on `:8080`. Hosts the catalog, policy, placement, and service provider managers in one binary. |
| **Catalog Manager**          | Manages service types, catalog items, and catalog item instances. Triggers placement when an instance is created.                       |
| **Policy Manager**           | Stores placement policies (Rego) and evaluates them via an embedded OPA engine.                                                         |
| **Placement Manager**        | Selects a service provider for a new instance by evaluating policies against available providers.                                       |
| **Service Provider Manager** | Tracks registered service providers and their health status.                                                                            |
| **PostgreSQL**               | Persistent storage for the control plane.                                                                                               |
| **NATS**                     | Message bus for communication between the Service Provider Manager and service providers.                                               |
| **Service Providers**        | External systems (e.g., KubeVirt) that create and manage the actual resources (VMs, containers, etc.).                                  |

## Request Flow

When a user creates a catalog item instance, the following happens:

```mermaid
sequenceDiagram
    participant User
    participant CP as Control Plane
    participant CM as Catalog Manager
    participant PLM as Placement Manager
    participant PM as Policy Manager
    participant SPM as SP Manager
    participant SP as KubeVirt SP

    User->>CP: Create catalog item instance
    CP->>CM: POST /catalog-item-instances
    CM->>PLM: Request placement
    PLM->>PM: Evaluate policies (embedded OPA)
    PM-->>PLM: Placement decision
    PLM->>SPM: Create resource on provider
    SPM->>SP: Create VM
    SP-->>User: VM scheduling
```

1. The **Catalog Manager** receives the request and asks the **Placement
   Manager** to find a suitable provider.
2. The **Placement Manager** evaluates placement policies through the **Policy
   Manager**, which uses an embedded OPA engine to evaluate Rego.
3. Once a provider is selected, the resource is created on that provider through
   the **Service Provider Manager**.
