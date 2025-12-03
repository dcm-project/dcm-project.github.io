---
title: "ADR-001: Service Provider Registration Flow"
weight: 1
---

The DCM (Data Center Management) is designed to provide a unified control plane
for managing distributed infrastructure across multiple enclaves, including
air-gapped environments, regional datacenters, and isolated security zones (e.g.
ships, edge locations).   
A fundamental architectural decision must be made about how Service Providers
(SP) — the components that execute infrastructure provisioning work — become
known to and integrate with the DCM Control Plane. This decision directly
impacts scalability, security, network topology, operational model (whether
centralized DCM teams or distributed SME teams manage Service Provider
lifecycle).   

# Goal

Define the registration mechanism by which Service Providers become known to and
communicate with the DCM Control Plane.

# Non-Goals

* Implementing details of registration API  
* Service Provider authentication/Authorization  
* Service catalog schema  
* DCM Control Plane definition  
* Meta-service-provider design  
* Service Provider’s policies

# Proposed Architecture

## Terminology

Service Providers must register using the DCM Service Provider API to operate
within the DCM system. The Registration Handler component implements the
provider registration endpoints of the Service Provider API.  
The registration phase provides to the DCM Control Plane the SP endpoint,
metadata and capabilities, so it can route requests to the appropriate SP.  
The registration call can be initiated either by the SP itself during start up
phase or by a third party (e.g. platform admins) on behalf of the SP. Both
approaches use the same registration API.

The *initial implementation* will focus only on the **self registration flow**.

The *Service Provider API* is located in the Egress layer and defines the
contract between the DCM Control Plane and Service Providers. It includes
endpoints for provider registration, resource management, and provider queries.
The [Service Provider API
specification](https://github.com/Fale/dcm/blob/od/api/interoperabilityAPI.yaml)
is under development.

Within this architecture, the *Registration Handler* is a component within the
Service Provider API that implements the provider registration endpoints *(POST
/resource/{resourceKind}/provider* and related endpoints). When an SP registers,
the Registration Handler communicates with the Control Plane to update the
Service Registry and Service Catalog.

### Architectural Assumptions  
There must be network connectivity between Service Providers and the Service
Provider API.  
If the Service Provider API can't reach an SP, it can't route provisioning
requests to it, regardless of the registration or discovery method used.

## Registration Flow

### Static approach

Registration is per resource type. Each Service Provider may support multiple
resource types (e.g., VMs and Containers), but it must register **separately**
for each type. This design provides clear endpoint separation and avoids complex
capability matrices.

<img src="/images/adr/001-registration-flow/diagram-static.png" alt="Static
Registration Flow: Service Providers register with the Registration Handler,
which updates the Service Registry and Service Catalog" style="width: 100%;
height: auto;">


* Admins predefine Service Catalog offerings (e.g., "VM", "GPU")  
* Each Service Provider must implement Service Provider API contract at a
  reachable endpoint    
* Each Service Provider must be configured with the registration Handler URL
  during the deployment (via config file or env var).  
* A registration call must be made to the Service Provider API (Registration
  Handler endpoint) for each resource type the SP supports.   
  The payload will be defined in a dedicated ADR.  
  It may include, just as an example:  
  1. ProviderID  
  2. Endpoint URL (e.g.,
     [https://provider-1.local/api](https://provider-1.local/api))  
  3. Metadata (zone, region, resource constraints)  
  4. Operations supported for this resource type (e.g., *“create”, “delete”*)  
  5. References catalog service kind this provider can fulfill (e.g, “vm”,
     “container”)  
* The Registration Handler processes and validates the metadata  
* The Registration Handler internally updates both:  
  1. Service Registry with:  
     1. SP endpoint  
     2. metadata  
  2. Service Catalog with:  
     1. available SPs  
     2. SPs capabilities/catalog offering references  
* When user requests a catalog offering, Control Plane matches it to registered
  SPs that can fulfill it and calls the selected SP endpoint (endpoint must be
  reachable)

### Meta Service Provider

Some catalog items are composite services with dependencies (e.g.,
"PCI-compliant container and database" requires multiple resources).  
To maintain the architectural principle that "a single request always goes to a
single service provider," the proposed architecture suggests using a
*meta-service-provider*. It is a special type of service provider that:

* Fulfills composite catalog items (e.g., "PCI-compliant environment")  
* Internally breaks down the request into sub-requests to other service
  providers  
* Orchestrates the workflow and tracks state/metadata  
* Keeps the Control Plane API simple by preventing service provider
  implementation details from leaking into DCM

A meta-service-provider would register using the same registration approaches
described in this ADR

**Non-Goal**  
The design and implementation of meta-service-providers is out of scope for this
ADR, which focuses on the Service Provider registration mechanism.
*meta-service-provider* design will be addressed in a separate ADR.

### Update Service Provider capabilities flow

The registration endpoint is idempotent. If an SP's capabilities change
(typically due to a new version following a restart), the SP (or admin) can call
the same registration endpoint again. The Registration Handler will  update the
existing SP entry rather than creating a duplicate.

* SP capabilities changes   
* SP restarts and re-registers using the same Service Provider API registration
  endpoint  
* The Registration Handler detects that the SP already exists (same providerID)  
* The Registration Handler updates the existing Service Provider Registry and
  Service Catalog entry with the new capabilities



# Alternatives Considered / Rejected

## Registration Flow

### Dynamic Approach

This approach separates registration from capability advertisement. The benefit
is that the Control Plane always queries real-time capacity and availability
during placement decisions, rather than relying on potentially stale cached
capabilities. This is useful when SP capabilities change frequently based on
resource availability.  
Same as the static approach the registration process is per resource type. <img
src="/images/adr/001-registration-flow/diagram-dynamic.png" alt="Dynamic
Registration Flow: Service Providers register and the Registration Handler
queries their capabilities" style="width: 100%; height: auto;">


* Admins predefine Service Catalog offerings (e.g., "VM", "GPU")  
* Each Service Provider must implement Services API contract at a reachable
  endpoint  
* Each Service Provider must make a *minimal* registration call to the Service
  Provider API (Registration Handler endpoint) for each resource type with:  
  1. Endpoint URL (e.g.,
     [https://provider-1.local/api](https://provider-1.local/api))  
  2. Basic Metadata  
  3. (Note: no capabilities or catalog references at registration time)  
* The Registration Handler receives the request  
* The Registration Handler processes and validates the metadata  
* The Registration Handler internally updates only the Service Registry  
* Periodically, the control Plane makes a call to each SP registered
  `/providers/{id}/services` API  
* Each registered SP returns:  
  1. real-time capabilities, capacity, and availability  
  2. which predefined catalog offerings it can currently fulfill  
* When a user requests a catalog offering, Control Plane selects the best SP and
  calls its endpoint.

The Service Provider registration operates on a **push model**, where the SPs
proactively send registration information to the Service Provider API
(Registration Handler endpoints). However, during placement operations, the DCM
Control Plane **pulls** information from the Service Provider API.

* *Registration:*  
  The SP initiates the process by pushing registration information to the
  Control Plane.  
* Workflow Execution  
  The Control Plane pushes provisioning requests to the SP.

### Advantages

* Decentralized Control  
  It’s the SME team that maintains control over when their SPs become active in
  the system  
* Efficient Registration  
  Complete metadata is provided in a single registration call.  
* Scalability  
  Supports large-scale deployments, handling tens to hundreds of distributed SP
  instances  
* Industry Alignment  
  Consistent with established industry patterns (e.g., Kubernetes, Crossplane,
  Consul).

### Drawbacks

* Protocol Understanding  
  SP implementers are required to understand the registration protocol.  
* Explicit Registration  
  An explicit registration step is necessary; automatic discovery is not
  supported.  
* Re-registration on Change  
  Any changes to the SP endpoint necessitate a re-registration process.

## DCM discovers Service Providers

The DCM actively scans endpoints to discover and register SPs.

<img src="/images/adr/001-registration-flow/diagram-discover.png"
alt="Registration Flow: DCM discovers Service Providers" style="width: 100%;
height: auto;">



### Registration Flow

1. SP deploys and implements Services API that are listening on a network
   endpoint  
2. Discovery Scanner periodically scans ip addresses/ports/dns names (?)
   invoking the `GET /discover`  
3. SP replies with metadata payload  
4. Control Plane validates response and authenticate the SP identity  
5. CP updates Service Registry with SP endpoints and metadata  
6. CP update Service CAtalog with SP offered services

### Advantages

* Automatic Discovery  
  No explicit registration step is needed from the Service Provider (SP).  
* Centralized Control  
  The Control Plane manages the discovery process, providing a centralized view
  and timing control.  
* Passive SPs  
  SPs are passive; they wait to be discovered instead of actively registering.  
* Automatic Change Detection  
  Changes to SP endpoints can be automatically detected via re-scanning,
  provided the endpoint is reachable.

### Disadvantages

* Air-Gapped  
  Discovery fails in disconnected networks  
* Firewall Issues  
  Inbound scanning is typically blocked by network security policies.  
* Scalability Concerns  
  Scanning is impractical for hundreds of SPs across various networks and
  security zones.  
* Discovery Delay  
  A time gap exists between SP deployment and its actual discovery (dependent on
  the scan interval).  
* Network Configuration Overhead  
  Requires maintenance of network ranges and port configurations for scanning.  
* SP Cooperation Still Needed  
  SPs must still implement a discovery endpoint and respond with metadata.  
* Security Risks  
  Network scanning can trigger security alerts or violate existing security
  policies.  
* Lack of Readiness Control  
  SME teams cannot control when SPs join the system or signal maintenance
  windows  
* Persistent Network Routes  
  The Control Plane must maintain network routes to all SP networks.

