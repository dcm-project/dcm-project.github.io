---
title: Policies
type: docs
weight: 5
---

Policies are [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) rules (the OPA policy language) that validate service provider resources and control where they are placed. During the placement flow, DCM evaluates all enabled policies in priority order (lower number = evaluated first). A policy can reject a request or select a specific provider for it. It may also alter or set values.

## Creating a Policy

Define the policy in a YAML file and use `dcm policy create` to submit it.

Here is an example policy file:

```yaml
# policy.yaml
display_name: Provider
policy_type: GLOBAL
priority: 1
rego_code: |
  package provider.selector

  import rego.v1

  spm_url := "http://service-provider-manager:8080/api/v1alpha1/providers"

  main := {"rejected": true, "rejection_reason": "spec.service_type is required"} if {
      not input.spec.service_type
  }

  main := result if {
      service_type := input.spec.service_type
      response := http.send({
          "method": "GET",
          "url": sprintf("%s?type=%s", [spm_url, service_type]),
          "headers": {"Accept": "application/json"},
      })
      providers := response.body.providers
      ready_providers := [p | some p in providers; p.health_status == "ready"]
      result := _providers_result(ready_providers, service_type)
  }

  _providers_result(providers, service_type) := {"rejected": true, "rejection_reason": msg} if {
      count(providers) == 0
      msg := sprintf("no ready providers found for service type '%s'", [service_type])
  }

  _providers_result(providers, _) := {"rejected": false, "selected_provider": provider} if {
      count(providers) > 0
      sorted_names := sort([p.name | some p in providers])
      provider := sorted_names[0]
  }
```

> **Note:** This REGO code assumes it can access the `service-provider-manager` to get the list of providers. Then, it filters only the `ready` ones, sorts alphabetically and returns the first one

### Field Reference

| Field | Description |
|-------|-------------|
| `display_name` | A human-readable name for the policy. |
| `policy_type` | The scope of policy (e.g., `GLOBAL`). |
| `priority` | Evaluation order. Lower numbers are evaluated first. |
| `enabled` | Whether the policy is active (`true` or `false`). |
| `rego_code` | The Rego source code. Must define a `main` rule with `rejected`, and either `rejection_reason` or `selected_provider` fields. |
| `label_selector` | `key:value` pairs used to match between the policy and the `metadata.labels` field of the provisioned resource |

> **Note:** `label_selector` may also use the `service_type` key to match based on the resource's `service_type`

### Rego Rule Structure

The `main` rule receives an `input` object and must return an output object.

#### Input

The `input` object includes:

| Field | Description |
|-------|-------------|
| `spec` | The current (patched) request payload. While policies do not have to be specific for service types, they will need to know the expected content. |
| `constraints` | The accumulated constraints context from prior policies in the chain. |
| `provider` | The currently selected service provider (empty string initially, populated as policies are evaluated). |
| `service_provider_constraints` | The accumulated service-provider constraints from prior policies. |

#### Output

The `main` rule must return an object with the following fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `rejected` | boolean | Yes | Set to `true` to reject the placement request. Requests are approved by default. |
| `rejection_reason` | string | No | A human-readable reason when the request is rejected. |
| `selected_provider` | string | No | The name of the service provider chosen to fulfill the request. |
| `service_provider_constraints` | object | No | Constraints on which service providers are allowed. Contains `allow_list` (list of allowed provider names) and `patterns` (list of regex patterns for matching allowed providers). |
| `patch` | map | No | A dictionary of values to set or override in the request payload. |
| `constraints` | map | No | Field constraints for subsequent policies, following [JSON Schema (draft 2020-12)](https://json-schema.org/draft/2020-12/json-schema-validation). Supports `const` (immutable), numeric constraints (`minimum`, `maximum`, `multipleOf`), string patterns (`pattern`, `minLength`, `maxLength`), enumerations (`enum`), array constraints (`minItems`, `maxItems`), and conditional logic (`if`/`then`/`else`). |

> **Note:** While no single policy is required to set the `selected_provider` field, the combination of all processed policies must set one; otherwise, placement will fail.

### Create Command

```bash
dcm policy create --from-file policy.yaml
```

To specify a custom ID for the policy:

```bash
dcm policy create --from-file policy.yaml --id prefer-provider-a
```

Verify the policy was created:

```bash
dcm policy get prefer-provider-a
```

## Listing Policies

Use `dcm policy list` to view all policies:

```bash
dcm policy list
```

Sample output:

```
ID                DISPLAY NAME         TYPE     PRIORITY   ENABLED   CREATED
prefer-provider-a Prefer Provider A    GLOBAL   10         true      2026-04-10T08:30:00Z
deny-large-vms    Deny Large VMs       GLOBAL   20         true      2026-04-11T14:22:00Z
dev-only-policy   Dev Only             USER     30         false     2026-04-12T09:15:00Z
```

### Optional Flags

| Flag | Description |
|------|-------------|
| `--filter` | A CEL filter expression to narrow results. |
| `--order-by` | Field and direction to sort by (e.g., `"priority asc"`). |
| `--page-size` | Maximum number of results per page (int32). |
| `--page-token` | Token for retrieving the next page of results. |

### Filter and Sort Examples

List only placement policies:

```bash
dcm policy list --filter "policy_type='PLACEMENT'"
```

Sort by priority in ascending order:

```bash
dcm policy list --order-by "priority asc"
```

Combine filter and sort with pagination:

```bash
dcm policy list --filter "enabled=true" --order-by "priority asc" --page-size 10
```

## Getting Policy Details

Use `dcm policy get` with the policy ID to retrieve full details:

```bash
dcm policy get prefer-provider-a
```

Example JSON output (using `-o json`):

```bash
dcm policy get prefer-provider-a -o json
```

```json
{
  "create_time": "2026-04-15T18:38:13.990296Z",
  "display_name": "Provider",
  "enabled": true,
  "id": "7eff7e73-4c14-4311-8673-e03916b00ece",
  "path": "policies/7eff7e73-4c14-4311-8673-e03916b00ece",
  "policy_type": "GLOBAL",
  "priority": 1,
  "rego_code": "package provider.selector\n\nimport rego.v1\n\nspm_url := \"http://service-provider-manager:8080/api/v1alpha1/providers\"\n\nmain := {\"rejected\": true, \"rejection_reason\": \"spec.service_type is required\"} if {\n    not input.spec.service_type\n}\n\nmain := result if {\n    service_type := input.spec.service_type\n    response := http.send({\n        \"method\": \"GET\",\n        \"url\": sprintf(\"%s?type=%s\", [spm_url, service_type]),\n        \"headers\": {\"Accept\": \"application/json\"},\n    })\n    providers := response.body.providers\n    ready_providers := [p | some p in providers; p.health_status == \"ready\"]\n    result := _providers_result(ready_providers, service_type)\n}\n\n_providers_result(providers, service_type) := {\"rejected\": true, \"rejection_reason\": msg} if {\n    count(providers) == 0\n    msg := sprintf(\"no ready providers found for service type '%s'\", [service_type])\n}\n\n_providers_result(providers, _) := {\"rejected\": false, \"selected_provider\": provider} if {\n    count(providers) \u003e 0\n    sorted_names := sort([p.name | some p in providers])\n    provider := sorted_names[0]\n}\n",
  "update_time": "2026-04-15T18:38:13.990296Z"
}
```

## Updating a Policy

Use `dcm policy update` with a patch file. The update uses **JSON Merge Patch** semantics -- only fields present in the patch file are modified; all other fields remain unchanged.

For example, to change the priority and disable a policy:

```yaml
# patch.yaml
priority: 5
enabled: false
```

```bash
dcm policy update prefer-provider-a --from-file patch.yaml
```

Verify the update:

```bash
dcm policy get prefer-provider-a
```

> **Note:** You do not need to include every field in the patch file. Only the fields you want to change should be present.

## Deleting a Policy

Use `dcm policy delete` with the policy ID:

```bash
dcm policy delete prefer-provider-a
```

> **Note:** Deleting a policy is permanent. Ensure the policy is no longer needed before deleting it.

## Policy Priority and Evaluation

During instance placement, DCM evaluates all **enabled** policies that match the request (based on the `label_selector`). If no matching policies are found, the request succeeds without policy evaluation.

### Evaluation Order

Policies are sorted by **level** first, then by **priority** within each level:

1. **Global** policies run first.
2. **Tenant** policies run second.
3. **User** policies run last.

Within each level, policies are sorted by `priority` in ascending order (lower number = evaluated first).

> **Note:** Choose priority values with gaps (e.g., 10, 20, 30) so you can insert new policies between existing ones without renumbering.

### Evaluation Pipeline

For each policy in order, the engine performs the following steps:

1. **Evaluate** the policy's Rego code. The `input` object includes the current patched `spec`, the accumulated `constraints`, the currently `selected_provider` (empty string initially), and the accumulated `service_provider_constraints`.
2. **Check rejection.** If the policy sets `rejected` to `true`, the placement request is denied immediately and the `rejection_reason` is returned to the caller. No further policies are evaluated.
3. **Validate constraints.** A lower-level policy cannot relax or remove a constraint set by a higher-level policy. If it attempts to do so, the request is aborted with a policy conflict error.
4. **Merge constraints.** New `constraints` from the policy are merged into the accumulated constraint context for subsequent policies.
5. **Validate patch.** The policy's `patch` is validated against the accumulated constraint context. For example, if a prior policy marked a field as immutable using a `const` constraint, any attempt to patch that field causes a policy conflict error.
6. **Apply patch.** Valid patches are applied to the request payload.
7. **Validate service provider.** If the policy returned a `selected_provider` and `service_provider_constraints` exist from prior policies, the selected provider is validated against those constraints.

After all policies have been evaluated, the engine returns the final payload, the selected provider, and the evaluation status to the Placement Manager. The status is `APPROVED` if the payload was not modified, or `MODIFIED` if any patches were applied.

---

For a step-by-step walkthrough, see [Create Placement Policy](../../getting-started/create-placement-policy/).
