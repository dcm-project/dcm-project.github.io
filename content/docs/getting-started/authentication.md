---
title: Authentication
type: docs
weight: 7
---

DCM can require authentication for control-plane API access. When authentication
is enabled, clients must present a valid JWT bearer token (or use the supported
proxy-header path). This page describes how to configure and use authenticated
environments. For compose and Helm operator steps, see the
[control-plane deploy guide](https://github.com/dcm-project/control-plane/blob/main/deploy/RUN.md#authentication).

## Overview

By default, local deployments run with authentication **disabled**
(`AUTH_DISABLED=true`). Any client that can reach the API can call protected
endpoints without credentials. This keeps getting-started tutorials simple.

For shared or production environments, operators **should** enable
authentication so every API request is tied to an identity. The control plane
validates JSON Web Tokens (JWTs) issued by an OpenID Connect (OIDC) identity
provider. The reference local stack uses [Keycloak](https://www.keycloak.org/)
with a pre-imported `dcm` realm.

The `/api/v1alpha1/health` endpoint stays **unauthenticated** whether or not
auth is enabled.

> **Service providers:** Service providers reach the control plane through the
> environment agent, not direct HTTP calls. End-to-end authentication for the
> agent and service providers is still in progress (for example
> [environment-agent#38](https://github.com/dcm-project/environment-agent/pull/38)
> and
> [environment-agent#35](https://github.com/dcm-project/environment-agent/pull/35)).
> Enabling auth on the control plane can still affect SP registration and
> instance workflows until that chain is complete. Use auth for CLI, UI, and
> direct API access first, or keep auth disabled while exercising full SP flows
> locally.

## How authentication works

1. A user or automation obtains an access token from the identity provider
   (Keycloak in the reference stack).
2. The client sends `Authorization: Bearer <access_token>` on each API request.
3. The control plane validates the token (signature, expiry, issuer, audience)
   using the provider's JWKS keys, then resolves the caller to a DCM **actor**.
4. On first login, unknown identities are provisioned automatically
   (just-in-time provisioning). No manual database setup is required for new
   Keycloak users in the `dcm` realm.

Tokens must include the `aud` claim the control plane expects. The default
audience is `dcm-api`; operators can change it with `AUTH_JWT_AUDIENCE`.

An optional **proxy-header** path accepts `X-Forwarded-User` and
`X-Forwarded-Preferred-Username` when `X-Auth-Proxy-Secret` matches
`AUTH_PROXY_SECRET`. See
[Authentication middleware](https://github.com/dcm-project/enhancements/blob/main/enhancements/authentication/authentication.md#2-authentication-middleware)
in the authentication enhancement. Most users rely on JWT bearer tokens instead.

## Prerequisites for authenticated deployments

Before users can log in, the platform operator must:

1. Run an OIDC identity provider reachable from both the control plane and
   clients (Keycloak with the `auth` compose profile in local stacks).
2. Set control-plane authentication environment variables (see below).
3. Ensure JWT clients exist for your callers (reference realm includes `dcm-cli`
   for the CLI device flow and `dcm-proxy` for programmatic access).
4. Set `DCM_ADMIN_SUBJECT` to the Keycloak `sub` of the bootstrap admin user
   when auth is first enabled.

To start the reference compose stack with authentication:

```bash
cd control-plane
cp deploy/.env.example deploy/.env
# Uncomment the "Enable authentication" block in deploy/.env
make compose-up AUTH=true
```

Keycloak is published at `http://localhost:8180` when the auth profile is
active. Lab usernames and passwords are documented in
[deploy/RUN.md](https://github.com/dcm-project/control-plane/blob/main/deploy/RUN.md#authentication).

For Kubernetes installs, create the auth secret and set `auth.enabled=true` as
described in the
[Helm chart README](https://github.com/dcm-project/control-plane/blob/main/deploy/helm/dcm/README.md#authentication).

### Control-plane configuration

| Variable            | Purpose                                                                             |
| ------------------- | ----------------------------------------------------------------------------------- |
| `AUTH_DISABLED`     | When `true`, auth middleware is bypassed (default for local dev).                   |
| `AUTH_ISSUER_URL`   | OIDC issuer URL for JWT validation (for example `http://keycloak:8080/realms/dcm`). |
| `AUTH_JWT_AUDIENCE` | Expected `aud` claim in access tokens (default `dcm-api`).                          |
| `AUTH_PROXY_SECRET` | Shared secret for the proxy-header auth path (optional).                            |
| `AUTH_CACHE_TTL`    | How long resolved actors are cached (default `60s`).                                |
| `DCM_ADMIN_SUBJECT` | Keycloak subject UUID for the seed admin actor (required when auth is enabled).     |

Copy secrets and toggles from `deploy/.env.example` into `deploy/.env`.

> **Warning:** Do not commit real production secrets to documentation or source
> control.

## Authenticated user workflows

### CLI (interactive)

The DCM CLI authenticates with the OIDC **device authorization** flow:

1. Configure the OIDC issuer (once per environment).
2. Run `dcm login`.
3. Open the URL shown in the terminal and approve the request in the browser.
4. Run normal `dcm` commands; the CLI attaches a bearer token and refreshes it
   before expiry.

#### Local compose: host access to Keycloak

The reference stack sets the Keycloak hostname so the issuer is
`http://keycloak:8080/realms/dcm`. That name resolves on the compose network,
not on your laptop by default. Before you run `dcm login` on the host, map
`keycloak` to the Keycloak container IP (repeat after recreating the container
if the IP changes):

```bash
KC_IP=$(podman inspect "$(podman ps -q --filter name=keycloak)" \
  --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
grep -qE '[[:space:]]keycloak$' /etc/hosts \
  && sudo sed -i -E "s/^[0-9.]+[[:space:]]+keycloak$/${KC_IP} keycloak/" /etc/hosts \
  || echo "${KC_IP} keycloak" | sudo tee -a /etc/hosts
getent hosts keycloak
```

Confirm the issuer string matches what the control plane expects:

```bash
curl -sf http://keycloak:8080/realms/dcm/.well-known/openid-configuration \
  | jq -r .issuer
```

You should see `http://keycloak:8080/realms/dcm`. The admin UI is also at
`http://localhost:8180`, but do not use `localhost:8180` as the issuer URL on
stock compose: discovery still advertises `keycloak:8080`, and the control plane
must use the same issuer as `AUTH_ISSUER_URL`.

#### Example login

Example for the reference Keycloak realm after host resolution is in place:

```bash
dcm login --issuer-url http://keycloak:8080/realms/dcm \
  --control-plane-url http://localhost:8080
dcm sp provider list
```

`dcm login` saves `issuer-url` in `~/.dcm/config.yaml`. Tokens are stored in the
OS keyring when available, otherwise in `~/.dcm/tokens.json` (mode `0600`).

To sign out and remove stored tokens:

```bash
dcm logout
```

See [CLI Configuration](../user-guide/cli-configuration/#authentication) for
flags and environment variables.

### Web UI (Backstage)

The [DCM UI](../user-guide/ui/) runs as a Backstage plugin. In authenticated
deployments, sign in through whatever identity provider your Backstage (or Red
Hat Developer Hub) instance uses. The plugin forwards OAuth2 bearer tokens to
the control plane, which validates them the same way as CLI and API tokens.

Configure Backstage SSO to use the same Keycloak realm (or corporate IdP) your
control plane trusts. The local compose `dcm-ui` image does not configure
Backstage SSO by itself; treat UI login as an operator concern tied to your
Backstage deployment.

### Adding users (Keycloak)

In the reference stack, create users in the Keycloak admin console
(`http://localhost:8180`, realm `dcm`). New users receive DCM actors on first
authenticated API call. See
[Adding users](https://github.com/dcm-project/control-plane/blob/main/deploy/RUN.md#adding-users)
in the deploy guide.

## Obtaining and using tokens

### CLI session tokens

After `dcm login`, you do not pass tokens manually. The CLI reads stored
credentials using `issuer-url` from config.

### Static bearer token (CI and scripts)

For non-interactive use, pass a bearer access token with `--token` (or set
`DCM_TOKEN`). Point the CLI at the control plane with `--control-plane-url` when
it is not the default `http://localhost:8080`:

```bash
dcm sp provider list \
  --token "<access-token>" \
  --control-plane-url http://localhost:8080
```

Static tokens skip the device flow and do not use the token store. Obtain access
tokens from your identity provider (for example Keycloak token endpoint with a
client your operator provisioned).

### Authenticating API requests

Send the access token on protected API requests:

```bash
curl -s \
  -H "Authorization: Bearer ${DCM_TOKEN}" \
  http://localhost:8080/api/v1alpha1/providers
```

Without a valid token when auth is enabled, the API returns `401 Unauthorized`.
If the identity is valid but the DCM actor is suspended or deactivated, the API
returns `403 Forbidden`.

## Troubleshooting

| Symptom                                     | Things to check                                                                                                                 |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `401 Unauthorized` on API or CLI            | Auth enabled on control plane; token present and not expired; `aud` includes `dcm-api`; issuer matches `AUTH_ISSUER_URL`.       |
| `dcm login` cannot reach issuer             | Host maps `keycloak` (see [host access](#local-compose-host-access-to-keycloak)); issuer matches discovery; TLS if using HTTPS. |
| Issuer / JWKS errors in control-plane logs  | `AUTH_ISSUER_URL` reachable from the control-plane container; Keycloak healthy (`auth` profile running).                        |
| CLI works but UI fails (or reverse)         | Backstage SSO and control plane must trust the same IdP and audience; plugin backend URL points at the control plane.           |
| `403 Forbidden` with valid token            | Actor suspended or deactivated; wait up to `AUTH_CACHE_TTL` after status changes.                                               |
| Service provider errors after enabling auth | SP traffic uses the environment agent; auth for agent and SP paths is still landing. See SP callout in [Overview](#overview).   |
| Device flow times out                       | Complete browser approval within the time shown; retry `dcm login`.                                                             |

Verify Keycloak readiness when using compose:

```bash
curl -sf http://localhost:8180/realms/dcm/.well-known/openid-configuration | jq .issuer
```

The issuer string must match `AUTH_ISSUER_URL` and the issuer you pass to
`dcm login`.

For container logs and restarts, see [Troubleshooting](troubleshooting/).
