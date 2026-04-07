---
title: Architecture Overview
type: docs
weight: 1
---

DCM (Data Center Management) is a control plane for managing infrastructure services across multiple providers. This page gives a high-level overview of how the components fit together.

## Components

```mermaid
graph TD
    User["User (CLI / API)"]
    GW["API Gateway<br/>(KrakenD :9080)"]

    subgraph Managers
        CM["Catalog Manager"]
        PM["Policy Manager"]
        PLM["Placement Manager"]
        SPM["Service Provider Manager"]
    end

    subgraph Infrastructure
        PG["PostgreSQL"]
        NATS["NATS"]
        OPA["OPA"]
    end

    subgraph Providers
        SP1["KubeVirt SP 1"]
        SP2["KubeVirt SP 2"]
    end

    User --> GW
    GW --> CM
    GW --> PM
    GW --> SPM

    CM --> PG
    PM --> PG
    PLM --> PG
    SPM --> PG

    PM --> OPA
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

| Component | Role |
|---|---|
| **API Gateway** | Single entry point for all API requests. Routes to the appropriate manager based on URL path. |
| **Catalog Manager** | Manages service types, catalog items, and catalog item instances. Triggers placement when an instance is created. |
| **Policy Manager** | Stores placement policies (Rego) and evaluates them via OPA. |
| **Placement Manager** | Selects a service provider for a new instance by evaluating policies against available providers. |
| **Service Provider Manager** | Tracks registered service providers and their health status. |
| **PostgreSQL** | Persistent storage for all managers. |
| **NATS** | Message bus for communication between the Service Provider Manager and service providers. |
| **OPA** | Evaluates Rego policies for placement decisions. |
| **Service Providers** | External systems (e.g., KubeVirt) that create and manage the actual resources (VMs, containers, etc.). |

## Request Flow

When a user creates a catalog item instance, the following happens:

```mermaid
sequenceDiagram
    participant User
    participant GW as API Gateway
    participant CM as Catalog Manager
    participant PLM as Placement Manager
    participant PM as Policy Manager
    participant OPA
    participant SPM as SP Manager
    participant SP as KubeVirt SP

    User->>GW: Create catalog item instance
    GW->>CM: POST /catalog-item-instances
    CM->>PLM: Request placement
    PLM->>PM: Evaluate policies
    PM->>OPA: Evaluate Rego
    OPA-->>PM: Placement decision
    PM-->>PLM: Placement decision
    PLM->>SPM: Create resource on provider
    SPM->>SP: Create VM
    SP-->>User: VM scheduling
```

1. The **Catalog Manager** receives the request and asks the **Placement Manager** to find a suitable provider.
2. The **Placement Manager** evaluates placement policies through the **Policy Manager** and **OPA**.
3. Once a provider is selected, the resource is created on that provider through the **Service Provider Manager**.
