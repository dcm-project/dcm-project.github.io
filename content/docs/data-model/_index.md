---
title: Data Model
type: docs
weight: 1
sidebar:
  open: true
---

# DCM Data Model

The DCM Data Model is the foundational layer that governs how all data in DCM is
represented, versioned, assembled, and governed. It defines the structure of every
resource, relationship, policy, and state record across the entire DCM lifecycle.

## Documents

- **[Context and Purpose](context-and-purpose/)** — Why the data model exists, core principles, provenance, and the artifact metadata standard.
- **[Four States](four-states/)** — The four-state model (Intent, Requested, Realized, Discovered), rehydration, and CI/CD integration.
- **[Data Layers and Assembly](layering-and-versioning/)** — Data layers, assembly process, override control, Layer Domain/Handle/Priority, and artifact metadata.
- **[Resource Type Hierarchy](resource-type-hierarchy/)** — The Resource Type Registry, catalog model, and provider hierarchy.
- **[Resource/Service Entities](resource-service-entities/)** — Entity definitions, ownership models, and lifecycle.
- **[Service Dependencies](service-dependencies/)** — Rehydration ordering and failure handling.
- **[Resource Grouping](resource-grouping/)** — Tenant model, Resource Groups, and grouping model.
- **[Entity Relationships](entity-relationships/)** — Universal relationship model for all entity connections.
- **[Information Providers](information-providers/)** — External data providers and the information type registry.
- **[Storage Providers](storage-providers/)** — Storage provider contracts for all DCM stores.
- **[Audit, Provenance, and Observability](audit-provenance-observability/)** — The three distinct concerns of audit, provenance, and observability.
