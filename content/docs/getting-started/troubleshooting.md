---
title: Troubleshooting
type: docs
weight: 10
---

Tips for diagnosing issues with your local DCM deployment.

## Viewing Container Logs

To view logs for a specific service:

```bash
podman-compose logs <service-name>
```

For example, to check the API gateway logs:

```bash
podman-compose logs gateway
```

Available service names: `gateway`, `postgres`, `nats`, `opa`, `service-provider-manager`, `catalog-manager`, `policy-manager`, `placement-manager`, `kubevirt-service-provider`.

### Follow Logs in Real Time

Use the `-f` flag to stream logs as they are produced:

```bash
podman-compose logs -f gateway
```

### Limit Log Output

To show only the last N lines:

```bash
podman-compose logs --tail 50 gateway
```

## Checking Container Status

To see which containers are running and their current state:

```bash
podman-compose ps
```

## Restarting a Service

If a service is unhealthy or not responding:

```bash
podman-compose restart <service-name>
```
