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

Available service names: `control-plane`, `postgres`, `nats`, `dcm-ui`,
`kubevirt-service-provider`.

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

## Authentication

If API calls or the CLI return `401 Unauthorized`, see
[Authentication](authentication/) for enabling auth, obtaining tokens, and
issuer configuration.

Common checks:

- Control plane has `AUTH_DISABLED=false` and `AUTH_ISSUER_URL` set.
- CLI: run `dcm login` or set `DCM_TOKEN` / `--token`.
- Token audience includes `dcm-api` (or your configured `AUTH_JWT_AUDIENCE`).
- Keycloak (or your IdP) is running and reachable from the control plane.

When auth is enabled, unauthenticated `curl` calls to protected endpoints fail
by design. The health endpoint remains open:

```bash
curl http://localhost:8080/api/v1alpha1/health
```
