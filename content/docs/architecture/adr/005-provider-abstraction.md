# ADR-005: Why Providers Exist and What They Do

**Status:** Accepted  
**Date:** March 2026  
**Docs:** Doc A (Provider Contract)

## Context

DCM must interact with many external systems: hypervisors, container platforms, network controllers, IPAM systems, identity services, other DCM instances, ITSM tools, and more. Each has its own API, data format, and operational model. Without a common abstraction, DCM becomes tightly coupled to specific infrastructure platforms.

## Decision

A **Provider** is any external system DCM interacts with through a defined contract. All providers share a base contract (registration, health check, sovereignty declaration, accreditation, zero trust authentication). What varies is the capability — what operations the provider exposes and what data flows in which direction.

Five provider types:

| Type | What it does | Example |
|------|-------------|---------|
| **Service** | Provisions and manages infrastructure resources | OpenStack Nova, KubeVirt, ACM |
| **Information** | Serves authoritative external data | CMDB, DNS, IPAM (InfoBlox) |
| **Meta** | Composes multiple providers into a compound service | Three-tier app, full-stack environment |
| **Auth** | Authenticates identities | Keycloak, LDAP, FreeIPA |
| **Peer DCM** | Another DCM instance for federation | Cross-region DCM |
| **Process** | Executes workflows without producing resources | Approval chains, ITSM integration |

The key mechanism is **Naturalization/Denaturalization**: DCM sends a unified payload to the provider. The provider translates (naturalizes) it into its native API format, acts on it, then translates (denaturalizes) the result back into DCM's unified format.

## Consequences

- Adding a new infrastructure platform means writing one provider — not changing DCM core
- Consumers don't know or care which provider fulfills their request
- Provider selection is policy-driven (placement), not consumer-chosen
- All provider interactions are audited and sovereignty-checked
