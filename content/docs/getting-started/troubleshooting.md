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

For example, to check the control-plane logs:

```bash
podman-compose logs control-plane
```

Available service names: `control-plane`, `postgres`, `nats`, `dcm-ui`, `kubevirt-service-provider`.

### Follow Logs in Real Time

Use the `-f` flag to stream logs as they are produced:

```bash
podman-compose logs -f control-plane
```

### Limit Log Output

To show only the last N lines:

```bash
podman-compose logs --tail 50 control-plane
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
