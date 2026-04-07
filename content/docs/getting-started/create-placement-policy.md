---
title: Create Placement Policy
type: docs
weight: 4
---

Placement policies control how DCM decides which service provider should handle a catalog item instance. Policies are written in [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/), the policy language used by Open Policy Agent (OPA). Each policy can accept or reject a placement request and optionally select a specific provider.

Policies have a `priority` — lower values are evaluated first.

## Define the Policy

Create a file called `kubevirt-policy.yaml` with the following content:

```yaml
display_name: kubevirt-provider
policy_type: GLOBAL
priority: 1
rego_code: |
  package kubevirt

  main := {
   "rejected": false,
   "selected_provider": "kubevirt-service-provider"
  }
```

This policy:
- Has the highest priority (`1`)
- Always selects `kubevirt-service-provider` as the target service provider
- Never rejects a request (`rejected: false`)

## Create the Policy

```bash
dcm policy create --from-file kubevirt-policy.yaml
```

## Verify the Policy

```bash
dcm policy list
```

You can also view a specific policy in YAML format:

```bash
dcm policy get <POLICY_ID> -o yaml
```
