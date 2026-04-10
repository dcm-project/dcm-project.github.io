---
title: Register Another Provider
type: docs
weight: 6
---

In DCM, service providers self-register by calling the Service Provider Manager API. When you started the KubeVirt service provider in the [Local Setup](../local-setup/), it automatically registered itself. In this guide, you'll register a second provider manually and create a policy that randomly selects between the two.

## Register a Second Provider

Start another instance of the KubeVirt service provider with a different name and namespace:

```bash
podman-compose --profile kubevirt run --name another-kubevirt-provider -d --no-deps \
  -e KUBERNETES_NAMESPACE=omachace-east \
  -e PROVIDER_NAME=another-kubevirt-provider \
  -e PROVIDER_ENDPOINT="http://another-kubevirt-provider:8081/api/v1alpha1/vms" \
  -e PROVIDER_ID=c9243c71-5ae0-4ee2-8a28-a83b3cb38d99 \
  kubevirt-service-provider
```

> **Note:** The `PROVIDER_ID` must be provided to ensure idempotent registration. The Service Provider Manager validates that no existing provider with the same name or ID is already registered with conflicting values.

> **Note:** The `KUBEVIRT_PROVIDER_NAME` must be specified so it matches the container's DNS hostname within the compose network. Other services use this name to reach the provider's endpoint.

The new provider will automatically register itself with the Service Provider Manager.

## Verify Both Providers Are Registered

```bash
curl -s http://localhost:9080/api/v1alpha1/providers | jq
```

You should see both `kubevirt-service-provider` and `another-kubevirt-provider` in the list.

## Create a Random Selection Policy

Now create a policy that randomly selects between the two providers. Create a file called `random-provider-policy.yaml`:

```yaml
display_name: random-provider-selection
policy_type: GLOBAL
priority: 1
rego_code: |
  package random_selection

  import rego.v1

  providers := ["kubevirt-service-provider", "another-kubevirt-provider"]

  main := {
    "rejected": false,
    "selected_provider": providers[idx]
  }

  idx := round(rand.intn("seed", count(providers)))
```

This Rego policy:
- Defines the two available providers: `kubevirt-service-provider` and `another-kubevirt-provider`
- Randomly picks one using `rand.intn`
- Returns the selected provider's name

> **Note:** If you previously created the `kubevirt-provider` policy from [Create Placement Policy](../create-placement-policy/), delete it first so the new policy takes effect:
> ```bash
> dcm policy delete <POLICY_ID>
> ```

## Create the Policy

```bash
dcm policy create --from-file random-provider-policy.yaml
```

## Verify the Policy

```bash
dcm policy list
```

## Test the Random Selection

Create two VM instances using the `my-vm.yaml` from [Create Instance of Small VM Catalog Item](../create-small-vm-instance/):

```bash
dcm catalog instance create --from-file my-vm.yaml
dcm catalog instance create --from-file my-vm.yaml
```

Now check which provider each instance was scheduled on:

```bash
dcm sp resource list
```

Example output:

```
ID                                    PROVIDER                   STATUS      CREATED
2788eb6c-644c-4a35-8272-67cb656c8913  kubevirt-service-provider  Scheduling  2026-03-26T08:42:39.086584Z
57aae98f-443d-4444-95dd-bc1e9ddc9406  another-kubevirt-provider  Scheduling  2026-03-26T08:42:44.87697Z
```

Each instance was placed on a different provider, confirming the random selection policy is working.
