---
title: "DCM Consumer API Specification"
type: docs
weight: 0
---

> **⚠️ Work in Progress**
>
> **This specification is a work in progress and is less mature than the core DCM data model documentation.** API endpoint paths, request/response structures, and authentication flows represent design intent and will be refined as implementation proceeds.
>
> **Do not build against this specification yet.** It is published to share design direction and invite feedback.
>
> Feedback and contributions welcome via [GitHub Issues](https://github.com/dcm-project/issues).

**Version:** 0.1.0-draft
**Status:** Design — Not yet implemented
**Document Type:** Technical Specification
**Related Documents:** [DCM Operator Interface Specification](dcm-operator-interface-spec.md) | [Four States](../data-model/02-four-states.md) | [Auth Providers](../data-model/19-auth-providers.md) | [Webhooks and Messaging](../data-model/18-webhooks-messaging.md)

---

## Abstract

This specification defines the interface by which consumers interact with the DCM Control Plane. It is the counterpart to the [Operator Interface Specification](dcm-operator-interface-spec.md), which covers what Service Providers implement. This specification covers what consumers call.

The Consumer API is the boundary between the Application domain and the Control Plane. It exposes DCM's service catalog, request submission, resource management, and audit capabilities in a unified interface. All operations are authenticated, authorized against the actor's Tenant scope, and fully audited.

---

## 1. Introduction

### 1.1 Scope

This specification covers:
- Authentication and session management
- Service Catalog browsing and discovery
- Resource request submission (all ingress paths)
- Resource lifecycle management (updates, suspension, decommission, rehydration)
- Request and resource status
- Audit trail access

It does not cover:
- Platform administration operations (covered by future Admin API spec)
- Service Provider registration and management (covered by Operator Interface Spec)
- Webhook and Message Bus subscription management (covered by doc 18)

### 1.2 Ingress Surfaces

The Consumer API is accessible via three ingress surfaces. All three are authenticated. All three run the same governance pipeline. The ingress surface affects the review workflow, never governance.

| Surface | Protocol | Review Model | Use Case |
|---------|----------|-------------|----------|
| **REST API** | HTTPS REST | Synchronous acknowledgment; async realization | Programmatic consumers, automation, Terraform providers |
| **Web UI** | Browser | Interactive PR-like review flow | Human consumers, Service Catalog browsing |
| **Git PR Ingress** | Git + webhook | Full GitOps PR workflow | GitOps-native teams, infrastructure-as-code workflows |

This specification primarily documents the REST API surface. The Git PR ingress YAML structure is documented in [Worked Examples](../data-model/04-examples.md), Section 2.

### 1.3 Base URL and Versioning

```
https://{dcm-instance}/api/v1/
```

All Consumer API endpoints are versioned. Breaking changes increment the version. Non-breaking additions do not.

### 1.4 Content Type

All requests and responses use `application/json`. The DCM Unified Data Model is expressed as JSON throughout the Consumer API.

---

## 2. Authentication

### 2.1 Token Acquisition

Consumers obtain a session token from the Auth Provider. The token acquisition method depends on the configured Auth Provider:

```
POST /api/v1/auth/token

# OIDC flow (most common):
{
  "grant_type": "authorization_code",
  "code": "<oidc-authorization-code>",
  "redirect_uri": "<registered-redirect-uri>"
}

# API key flow (service accounts):
{
  "grant_type": "api_key",
  "api_key": "<api-key-value>"
}

# Response:
{
  "token": "<session-token>",
  "token_type": "Bearer",
  "expires_at": "<ISO 8601>",
  "actor_uuid": "<uuid>",
  "mfa_verified": true,
  "scopes": ["read:catalog", "request:compute", "manage:owned"]
}
```

### 2.2 Request Authentication

All requests carry the session token as a Bearer token:

```
Authorization: Bearer <session-token>
```

### 2.3 Tenant Context

Actors may have access to multiple Tenants. The Tenant context for a request is declared in the header:

```
X-DCM-Tenant: <tenant-uuid>
```

If omitted and the actor has access to exactly one Tenant, that Tenant is used. If the actor has access to multiple Tenants and no Tenant header is provided, the request is rejected with `400 Bad Request` — Tenant ambiguity is never resolved silently.

### 2.4 Step-Up MFA

Some operations require step-up MFA regardless of session MFA status. When a step-up challenge is required, the API returns `403 Forbidden` with a challenge token:

```json
{
  "error": "step_up_required",
  "challenge_token": "<uuid>",
  "challenge_expires_at": "<ISO 8601>",
  "allowed_methods": ["totp", "push_notification"]
}
```

The consumer completes the MFA challenge and retries the request with the completed challenge token:

```
X-DCM-StepUp-Token: <completed-challenge-token>
```

---

## 3. Service Catalog

### 3.1 List Catalog Items

Returns catalog items available to the authenticated actor in their Tenant, filtered by RBAC.

```
GET /api/v1/catalog

Query parameters:
  category=<resource-type-category>    e.g., Compute, Network, Storage
  search=<string>                      full-text search across name and description
  tag=<string>                         filter by tag (repeatable)
  page=<int>                           pagination (default: 1)
  page_size=<int>                      results per page (default: 25, max: 100)

Response 200:
{
  "catalog_items": [
    {
      "catalog_item_uuid": "<uuid>",
      "resource_type": "Compute.VirtualMachine",
      "provider_uuid": "<uuid>",
      "display_name": "Standard Linux VM",
      "description": "General-purpose virtual machine with standard OS images",
      "tier": 1,
      "portability_class": "portable",
      "estimated_cost": {
        "unit": "per-hour",
        "amount": 0.32,
        "currency": "USD",
        "cost_confidence": "high"
      },
      "tags": ["compute", "linux", "general-purpose"],
      "deprecated": false
    }
  ],
  "total": 47,
  "page": 1,
  "page_size": 25
}
```

### 3.2 Describe Catalog Item

Returns the full schema for a catalog item — all fields, constraints, editability declarations, dependencies, and cost estimate.

```
GET /api/v1/catalog/{catalog_item_uuid}

Response 200:
{
  "catalog_item_uuid": "<uuid>",
  "resource_type": "Compute.VirtualMachine",
  "resource_type_spec_version": "2.1.0",
  "display_name": "Standard Linux VM",

  "schema": {
    "fields": [
      {
        "field_name": "cpu_count",
        "type": "integer",
        "required": true,
        "editable_post_realization": false,
        "constraint": {
          "visibility": "full",            # full | summary | hidden
          "type": "range",
          "min": 1,
          "max": 32,
          "allowed_values": [1, 2, 4, 8, 16, 32],
          "reason": "CPU counts must be powers of 2 for NUMA alignment"
        }
      },
      {
        "field_name": "memory_gb",
        "type": "integer",
        "required": true,
        "editable_post_realization": false,
        "constraint": {
          "visibility": "full",
          "type": "range",
          "min": 2,
          "max": 256
        }
      },
      {
        "field_name": "monitoring_agent",
        "type": "string",
        "required": false,
        "editable_post_realization": false,
        "constraint": {
          "visibility": "hidden",         # injected by policy — consumer cannot set
          "override": "immutable"
        }
      }
    ]
  },

  "dependencies": [
    {
      "resource_type": "Network.IPAddress",
      "relationship": "requires",
      "fulfillment": "automatic",          # DCM auto-allocates; consumer does not need to request separately
      "count": 1
    }
  ],

  "estimated_cost": {
    "breakdown": [
      { "component": "compute", "unit": "per-hour", "amount": 0.28, "currency": "USD" },
      { "component": "ip-allocation", "unit": "per-hour", "amount": 0.04, "currency": "USD" }
    ],
    "total_per_hour": 0.32,
    "currency": "USD"
  },

  "sovereignty": {
    "available_in_regions": ["EU-WEST", "EU-NORTH"],
    "data_residency_guarantee": "EU"
  }
}
```

### 3.3 Catalog Search

```
GET /api/v1/catalog/search?q=<query>

Returns catalog items matching the query across name, description, resource type, and tags.
Same response shape as List Catalog Items.
```

---

## 4. Request Submission

### 4.1 Submit Resource Request

Submits a new resource request. Returns immediately with an acknowledgment — realization is asynchronous.

```
POST /api/v1/requests

Request body:
{
  "catalog_item_uuid": "<uuid>",
  "fields": {
    "cpu_count": 4,
    "memory_gb": 8,
    "storage_gb": 100,
    "os_family": "rhel",
    "name": "payments-api-server-01"
  },
  "options": {
    "auto_approve": true,              # request auto-approval if policy permits
    "notify_on_completion": true,
    "notification_endpoint": "https://my-system.example.com/dcm/webhook"
  }
}

Response 202 Accepted:
{
  "request_uuid": "<uuid>",
  "entity_uuid": "<uuid>",            # the UUID the entity will have when realized
  "status": "ACKNOWLEDGED",
  "intent_state_ref": "<uuid>",
  "estimated_completion": "<ISO 8601>",
  "status_url": "/api/v1/requests/{request_uuid}/status",
  "dry_run_result": null              # null if auto-approve; populated if review required
}

Response 200 OK (if policy requires pre-validation report before submission):
{
  "dry_run": true,
  "validation_result": {
    "policies_evaluated": [...],
    "gatekeeper_decisions": [{ "policy": "vm-size-limits", "result": "approved" }],
    "estimated_cost": {...},
    "sovereignty_check": { "satisfied": true, "constraints": ["data_residency: EU"] },
    "would_auto_approve": true
  }
}
```

### 4.2 Request Status

```
GET /api/v1/requests/{request_uuid}/status

Response 200:
{
  "request_uuid": "<uuid>",
  "entity_uuid": "<uuid>",
  "status": "PROVISIONING",
  "status_history": [
    { "status": "ACKNOWLEDGED", "at": "2026-03-15T09:00:00Z" },
    { "status": "ASSEMBLING",   "at": "2026-03-15T09:00:02Z" },
    { "status": "DISPATCHED",   "at": "2026-03-15T09:00:47Z" },
    { "status": "PROVISIONING", "at": "2026-03-15T09:01:05Z" }
  ],
  "current_step": "Provider is provisioning the resource",
  "estimated_completion": "2026-03-15T09:05:00Z"
}

# Terminal status response:
{
  "request_uuid": "<uuid>",
  "entity_uuid": "<uuid>",
  "status": "COMPLETED",
  "completed_at": "2026-03-15T09:03:12Z",
  "resource_url": "/api/v1/resources/{entity_uuid}"
}

# Failed request:
{
  "request_uuid": "<uuid>",
  "entity_uuid": "<uuid>",
  "status": "FAILED",
  "failed_at": "2026-03-15T09:02:45Z",
  "failure_reason": "Provider capacity exhausted — all eligible providers at capacity",
  "retry_eligible": true,
  "retry_after": "PT15M"
}
```

### 4.3 Consumer Request Status Lifecycle

```
ACKNOWLEDGED    → request received; intent created
ASSEMBLING      → Request Payload Processor running layer assembly
AWAITING_APPROVAL → policy requires human review before dispatch (PR open)
APPROVED        → PR merged; dispatching to provider
DISPATCHED      → provider received payload; awaiting confirmation
PROVISIONING    → provider executing
COMPLETED       → provider confirmed realization; Realized State written
FAILED          → terminal; failure_reason and retry_eligible populated
CANCELLED       → consumer-initiated cancellation before PROVISIONING
CANCELLING      → cancellation in progress (provider notified)
```

### 4.4 Cancel Request

Cancellation is only available before the PROVISIONING state. Once a provider is executing, cancellation moves to CANCELLING and depends on provider support.

```
DELETE /api/v1/requests/{request_uuid}

Response 202 Accepted:
{
  "request_uuid": "<uuid>",
  "status": "CANCELLING",
  "message": "Cancellation requested. Provider will be notified if dispatch has occurred."
}

Response 409 Conflict (if cancellation not possible):
{
  "error": "cancellation_not_available",
  "reason": "Resource is in PROVISIONING state. Cancellation requires provider support.",
  "provider_supports_cancellation": false
}
```

---

## 5. Resource Management

### 5.1 List Owned Resources

```
GET /api/v1/resources

Query parameters:
  resource_type=<fqn>
  lifecycle_state=<state>
  drift_status=<clean|drifted|unknown>
  tag=<string>
  page=<int>
  page_size=<int>

Response 200:
{
  "resources": [
    {
      "entity_uuid": "<uuid>",
      "resource_type": "Compute.VirtualMachine",
      "display_name": "payments-api-server-01",
      "lifecycle_state": "OPERATIONAL",
      "drift_status": "clean",
      "owned_by_tenant_uuid": "<uuid>",
      "created_at": "<ISO 8601>",
      "provider_uuid": "<uuid>",
      "estimated_cost_per_hour": 0.32
    }
  ],
  "total": 12
}
```

### 5.2 Describe Resource

```
GET /api/v1/resources/{entity_uuid}

Response 200:
{
  "entity_uuid": "<uuid>",
  "resource_type": "Compute.VirtualMachine",
  "lifecycle_state": "OPERATIONAL",
  "drift_status": "clean",
  "last_discovered_at": "<ISO 8601>",

  "fields": {
    "cpu_count": {
      "value": 4,
      "confidence": { "band": "very_high", "score": 98 },
      "editable": false
    },
    "memory_gb": {
      "value": 8,
      "confidence": { "band": "very_high", "score": 98 },
      "editable": false
    }
  },

  "relationships": [
    {
      "type": "attached_to",
      "related_entity_uuid": "<vlan-uuid>",
      "related_entity_type": "Network.VLAN",
      "stake_strength": "required"
    }
  ],

  "cost": {
    "current_billing_state": "billable",
    "estimated_cost_per_hour": 0.32,
    "currency": "USD"
  },

  "rehydration_constraints": {
    "min_auth_level": "oidc_mfa"
  },

  "pending_provider_notifications": [
    {
      "notification_uuid": "<uuid>",
      "notification_type": "auto_scale",
      "submitted_at": "<ISO 8601>",
      "status": "pending_approval",
      "changed_fields": ["memory_gb"],
      "approval_url": "/api/v1/resources/{entity_uuid}/provider-notifications/{notification_uuid}/approve"
    }
  ]
}
```

### 5.3 Update Editable Fields (Targeted Delta)

Updates one or more editable fields on a realized resource. Does not re-run layer assembly — only the declared changes are dispatched to the provider.

```
PATCH /api/v1/resources/{entity_uuid}

Request body:
{
  "updates": {
    "name": "payments-api-server-01-renamed"
  },
  "reason": "Renamed to align with new naming convention"
}

Response 202 Accepted:
{
  "update_request_uuid": "<uuid>",
  "entity_uuid": "<uuid>",
  "status": "DISPATCHED",
  "fields_updated": ["name"],
  "status_url": "/api/v1/requests/{update_request_uuid}/status"
}

Response 422 Unprocessable (if field is not editable):
{
  "error": "field_not_editable",
  "field": "cpu_count",
  "reason": "cpu_count is not declared as editable post-realization for this resource type"
}
```

### 5.4 Suspend Resource

```
POST /api/v1/resources/{entity_uuid}/suspend

Request body:
{
  "reason": "Taking offline for maintenance window",
  "auto_resume_at": "2026-03-16T06:00:00Z"    # optional
}

Response 202 Accepted:
{
  "entity_uuid": "<uuid>",
  "status": "SUSPENDING",
  "auto_resume_at": "2026-03-16T06:00:00Z"
}
```

### 5.5 Decommission Resource

```
DELETE /api/v1/resources/{entity_uuid}

Request body:
{
  "reason": "Project completed — resource no longer needed",
  "force": false    # true to force even if non-required stakes/relationships exist
                    # cannot force decommission if required stakes exist
}

Response 202 Accepted:
{
  "entity_uuid": "<uuid>",
  "status": "DECOMMISSIONING"
}

Response 409 Conflict (required stakes or dependencies active):
{
  "error": "decommission_deferred",
  "reason": "Resource has active required stake relationships",
  "active_required_stakes": [
    {
      "stakeholder_entity_uuid": "<uuid>",
      "stakeholder_resource_type": "Compute.VirtualMachine",
      "stake_strength": "required"
    }
  ],
  "resolution": "Release all required stakes before decommissioning, or request stakeholders to migrate"
}
```

### 5.6 Trigger Rehydration

```
POST /api/v1/resources/{entity_uuid}/rehydrate

Request body:
{
  "source": "realized",              # intent | requested | realized
  "placement": {
    "re_evaluate": false
  },
  "governance": {
    "policy_version": "current"
  },
  "reason": "Provider migration — EU-WEST-Prod-1 being decommissioned"
}

Response 202 Accepted:
{
  "rehydration_request_uuid": "<uuid>",
  "entity_uuid": "<uuid>",
  "status": "ACKNOWLEDGED",
  "lease_uuid": "<uuid>",
  "status_url": "/api/v1/requests/{rehydration_request_uuid}/status"
}

Response 409 Conflict (rehydration lease already held):
{
  "error": "rehydration_lease_held",
  "lease_held_since": "<ISO 8601>",
  "lease_expires_at": "<ISO 8601>",
  "retry_after": "PT2H"
}

Response 403 Forbidden (step-up MFA required):
{
  "error": "step_up_required",
  "reason": "Entity min_auth_level requires hardware_token_mfa for rehydration"
}
```

---


### 5.7 Provider Update Notification Approval

When a provider submits an update notification that requires consumer approval, the consumer receives a notification and the resource enters `PENDING_REVIEW` state. The consumer approves or rejects via this endpoint.

```
GET /api/v1/resources/{entity_uuid}/provider-notifications

Response 200:
{
  "notifications": [
    {
      "notification_uuid": "<uuid>",
      "notification_type": "auto_scale",
      "provider_uuid": "<uuid>",
      "submitted_at": "<ISO 8601>",
      "status": "pending_approval",
      "change_summary": "Provider reports memory_gb increased from 8 to 16",
      "change_reason": "Auto-scale policy triggered at 85% memory utilization",
      "changed_fields": {
        "memory_gb": { "previous_value": 8, "new_value": 16 }
      }
    }
  ]
}

POST /api/v1/resources/{entity_uuid}/provider-notifications/{notification_uuid}/approve
{
  "decision": "approve | reject",
  "reason": "<optional human-readable reason>"
}

Response 202 Accepted:
{
  "notification_uuid": "<uuid>",
  "decision": "approve",
  "processed_at": "<ISO 8601>",
  "realized_state_uuid": "<uuid | null>"
}
```

**On approval:** A new Requested State record is created (`source_type: provider_update`, actor: consumer approver). A new Realized State snapshot is written. The entity exits PENDING_REVIEW.

**On rejection:** The notification is rejected. The discrepancy between provider state and DCM Realized State becomes a drift event. The entity exits PENDING_REVIEW with an active drift record.


## 6. Audit Trail

### 6.1 Query Audit Records for a Resource

```
GET /api/v1/resources/{entity_uuid}/audit

Query parameters:
  from=<ISO 8601>         start of time range
  to=<ISO 8601>           end of time range
  action=<action>         filter by action type
  actor_type=<human|service_account|system>
  page=<int>
  page_size=<int>

Response 200:
{
  "audit_records": [
    {
      "record_uuid": "<uuid>",
      "timestamp": "<ISO 8601>",
      "action": "PROVISION",
      "actor": {
        "uuid": "<uuid>",
        "type": "human",
        "display_name": "Jane Smith"
      },
      "summary": "VirtualMachine provisioned via EU-WEST-Prod-1",
      "correlation_id": "<uuid>"
    }
  ],
  "total": 47,
  "chain_integrity": "verified"      # verified | unverifiable | compromised
}
```

### 6.2 Follow Correlation ID

For cross-state correlation — following a request from Intent through all states:

```
GET /api/v1/audit/correlation/{correlation_id}

Response 200:
{
  "correlation_id": "<uuid>",
  "entity_uuid": "<uuid>",
  "timeline": [
    { "state": "intent",     "record_uuid": "<uuid>", "timestamp": "..." },
    { "state": "requested",  "record_uuid": "<uuid>", "timestamp": "..." },
    { "state": "realized",   "record_uuid": "<uuid>", "timestamp": "..." }
  ],
  "cross_dcm_refs": []               # cross-DCM records if federation involved
}
```

---

## 7. Error Model

All error responses follow a consistent structure:

```json
{
  "error": "<error_code>",
  "message": "<human-readable description>",
  "request_id": "<uuid>",
  "timestamp": "<ISO 8601>",
  "details": {}                      # error-specific additional context
}
```

**Standard error codes:**

| HTTP Status | Error Code | Meaning |
|-------------|-----------|---------|
| 400 | `invalid_request` | Malformed request or missing required fields |
| 400 | `tenant_ambiguous` | Actor has multiple Tenants; X-DCM-Tenant header required |
| 401 | `authentication_required` | No token or expired token |
| 403 | `authorization_denied` | Token valid but insufficient permissions |
| 403 | `step_up_required` | Operation requires step-up MFA challenge |
| 404 | `not_found` | Entity, catalog item, or request not found |
| 409 | `decommission_deferred` | Decommission blocked by active stakes or dependencies |
| 409 | `rehydration_lease_held` | Entity already being rehydrated |
| 409 | `field_not_editable` | Targeted delta attempted on non-editable field |
| 422 | `policy_rejected` | GateKeeper policy rejected the request |
| 422 | `constraint_violated` | Field value violates declared constraint |
| 429 | `rate_limit_exceeded` | Actor has exceeded request rate limit |
| 503 | `assembly_unavailable` | Request Payload Processor temporarily unavailable |

---

## 8. Conformance Levels

The Consumer API defines three conformance levels, mirroring the Operator Interface Specification model:

**Level 1 — Read-Only:** Catalog browsing and resource status queries only. No request submission or resource management. Suitable for reporting and dashboard integrations.

**Level 2 — Standard:** Full request submission, status tracking, and basic resource management (update editable fields, decommission). Required for all self-service portal implementations.

**Level 3 — Full:** All Level 2 operations plus rehydration, audit trail access, and correlation queries. Required for ITSM integrations and compliance tooling.

---

*Document maintained by the DCM Project. For questions or contributions see [GitHub](https://github.com/dcm-project).*
