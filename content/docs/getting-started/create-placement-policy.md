---
title: Create Placement Policy
type: docs
weight: 4
---

Placement policies control how DCM decides which environment agent should handle
a catalog item instance. Policies are written in
[Rego](https://www.openpolicyagent.org/docs/latest/policy-language/), the policy
language used by Open Policy Agent (OPA). Each policy can accept or reject a
placement request and optionally select a specific agent.

Policies have a `priority` — lower values are evaluated first.

## Define the Policy

Create a file called `kubevirt-policy.yaml` with the following content:

```yaml
display_name: local-agent
policy_type: GLOBAL
priority: 1
rego_code: |
  package local

  main := {
   "rejected": false,
   "selected_agent": "local-agent"
  }
```

This policy:

- Has the highest priority (`1`)
- Always selects `local-agent` as the target agent
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
