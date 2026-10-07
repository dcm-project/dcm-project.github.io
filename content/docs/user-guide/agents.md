---
title: Agents
type: docs
weight: 2
---

Environment agents are lightweight processes that run in a target environment
and act as the intermediary between DCM and the service providers deployed
there. Each agent registers with the control plane, reports health via
heartbeats, and routes resource operation requests to the appropriate service
provider.

Agents typically **self-register** when they start. The CLI exposes
**read-only** list and get operations so you can inspect registered agents and
their health. Manual registration is also available from the
[DCM UI](../ui/#agents) when automatic registration is not used.

## Listing Agents

Use `dcm agent list` to display all registered environment agents:

```bash
dcm agent list
```

Example output:

```
ID         NAME            ENVIRONMENT  HEALTH  CREATED
agent-123  kubevirt-east   production   ready   2026-03-09T10:00:00Z
agent-456  kubevirt-west   staging      ready   2026-03-10T14:45:00Z
```

### Filtering by Health Status

Use the `--health-status` flag to show only agents with a specific health status
(`ready`, `congested`, or `unavailable`):

```bash
dcm agent list --health-status ready
```

### Pagination

For environments with many agents, use pagination flags to control the output:

- `--page-size` — Maximum number of agents to return per page.
- `--page-token` — Token for retrieving the next page of results (returned in
  the previous response).

```bash
dcm agent list --page-size 10
```

## Getting Agent Details

Use `dcm agent get` to retrieve detailed information about a single agent:

```bash
dcm agent get agent-123
```

To view the full details as JSON:

```bash
dcm agent get agent-123 -o json
```

Example JSON output:

```json
{
  "agent_id": "agent-123",
  "name": "kubevirt-east",
  "environment": "production",
  "service_types": ["vm", "container"],
  "cost": "medium",
  "topic_name": "dcm.agent.kubevirt-east",
  "health_status": "ready",
  "last_heartbeat": "2026-03-09T10:05:00Z",
  "create_time": "2026-03-09T10:00:00Z",
  "update_time": "2026-03-09T10:05:00Z"
}
```

## Agent Health

Each agent reports a **health status** based on its last heartbeat:

- **`ready`** — The agent is reachable and operating normally.
- **`congested`** — The agent is reachable but its message consumer lag is
  elevated.
- **`unavailable`** — The agent has not sent a recent heartbeat or is otherwise
  not available for placement.

These fields are updated automatically as agents send periodic heartbeats to
DCM.
