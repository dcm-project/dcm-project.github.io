---
title: Local Setup
type: docs
weight: 2
---

Learn how to set up and run DCM on your local machine.

## Prerequisites

- [Podman](https://podman.io/) and `podman-compose` installed
- [Go](https://go.dev/) (for building the CLI)
- (Optional) A Kubernetes cluster with [KubeVirt](https://kubevirt.io/) for the kubevirt-service-provider

## Quick Start

Clone the [api-gateway](https://github.com/dcm-project/api-gateway) repository and start all core services (gateway, postgres, nats, opa, and all managers):

```bash
git clone https://github.com/dcm-project/api-gateway.git
cd api-gateway
podman-compose up -d
```

The API gateway will be available at `http://localhost:9080`.

## Running with the KubeVirt Service Provider

The `kubevirt-service-provider` is behind a compose profile and does not start by default.
To include it, set the required environment variables and activate the `kubevirt` profile:

```bash
export KUBEVIRT_NAMESPACE=vms
export KUBEVIRT_KUBECONFIG="/path/to/kubeconfig"
podman-compose --profile kubevirt up -d
```

> **Note:** The namespace set in `KUBEVIRT_NAMESPACE` must already exist in your Kubernetes cluster.

## Verifying the Deployment

Check that all services are running:

```bash
podman-compose ps
```

Check health endpoints through the gateway:

```bash
curl http://localhost:9080/api/v1alpha1/health/providers
curl http://localhost:9080/api/v1alpha1/health/catalog
curl http://localhost:9080/api/v1alpha1/health/policies
curl http://localhost:9080/api/v1alpha1/health/placement
```

If you deployed with the KubeVirt provider, you can also list the registered providers:

```bash
curl http://localhost:9080/api/v1alpha1/providers
```

## Setting Up the CLI

The DCM CLI (`dcm`) lets you interact with the DCM control plane from the command line. Clone the [cli](https://github.com/dcm-project/cli) repository and build the binary:

```bash
git clone https://github.com/dcm-project/cli.git
cd cli
make build
```

The binary will be available at `bin/dcm`. You can move it to a directory in your `PATH`:

```bash
sudo cp bin/dcm /usr/local/bin/
```

By default, the CLI connects to the API gateway at `http://localhost:9080`. You can verify it's working with:

```bash
dcm version
```
