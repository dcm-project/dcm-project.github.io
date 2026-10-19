# DCM Documentation Release-Validation Test Plan

## Purpose

Validate that the documentation in this repository is buildable, navigable, and
operationally correct against the DCM implementation and deployment
repositories. The plan is intended to be reused for documentation releases and
for release candidates of the DCM stack.

This is a documentation acceptance plan, not a replacement for unit, subsystem,
or service-provider tests. It verifies that a reader can follow the published
instructions and reach the behavior described by the current DCM implementation.

The standard DCM service-provider architecture uses an environment agent as the
registration and routing layer between service providers and the control plane.
The plan validates that boundary explicitly. A broader effort to resynchronize
all user documentation with service and application repositories is follow-up
work, not an implicit assumption that every page is covered by this release
gate.

## Release Inputs

Record the exact revisions before execution. Do not validate against moving
`main` branches without recording the resolved commit IDs.

| Input                            | Repository or location                                                       | Revision |
| -------------------------------- | ---------------------------------------------------------------------------- | -------- |
| Documentation                    | `dcm-project/dcm-project.github.io`                                          |          |
| Control plane and deployment     | `dcm-project/control-plane`                                                  |          |
| CLI                              | `dcm-project/cli`                                                            |          |
| E2E/deployment utilities         | `dcm-project/utilities`                                                      |          |
| Environment agent                | `dcm-project/environment-agent`                                              |          |
| Enhancements                     | `dcm-project/enhancements`                                                   |          |
| Provider used by the walkthrough | `dcm-project/kubevirt-service-provider` or the provider named by the release |          |
| Published site and deployment    | GitHub Pages URL and deployment workflow run                                 |          |
| Test date and operator           |                                                                              |          |

If a release uses a tagged version, record the tag and the commit it resolves
to. Capture any local patches or configuration overrides in the test results.

## Source Of Truth

Cross-reference each documentation claim with the implementation source before
calling a discrepancy a defect.

| Documentation area                              | Primary source                                                                                            | Secondary source                                      |
| ----------------------------------------------- | --------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| Local stack startup and health                  | [`control-plane/deploy/RUN.md`](https://github.com/dcm-project/control-plane/blob/main/deploy/RUN.md)     | `control-plane/deploy/compose.yaml`                   |
| CLI commands, flags, config, output             | [`cli/.ai/specs/dcm-cli.spec.md`](https://github.com/dcm-project/cli/blob/main/.ai/specs/dcm-cli.spec.md) | CLI command implementation and E2E tests              |
| API paths and schemas                           | `control-plane/api/**/openapi.yaml`                                                                       | Generated clients under `control-plane/pkg/**/client` |
| Agent registration and SP routing               | `environment-agent/api/**/openapi.yaml` and environment-agent deployment docs                             | Agent specs and embedded SP configuration             |
| Full-stack deployment and provider setup        | [`utilities/README.md`](https://github.com/dcm-project/utilities/blob/main/README.md)                     | `utilities/scripts/`, `utilities/tests/`              |
| Runtime behavior and expected state transitions | `control-plane/test/subsystem/**`                                                                         | `utilities/tests/e2e/**`                              |
| Enhancement pages                               | [`dcm-project/enhancements`](https://github.com/dcm-project/enhancements)                                 | Enhancement links rendered by Hugo                    |

When sources disagree, record the disagreement and the selected release contract
in the results. Do not silently normalize one source to another.

## Test Environment

### Automated checks

- Hugo Extended version compatible with the repository's `go.mod` and theme.
- Go toolchain required by the repository.
- Node.js/npm for the fallback spell checker and Prettier checks.
- Network access to the Hugo module and raw GitHub enhancement content.
- A clean checkout of the documentation repository.

### Live-stack checks

- Podman and `podman-compose` (or the supported equivalent documented by the
  release).
- Go and a working `dcm` CLI build.
- A control-plane stack with PostgreSQL, NATS, control-plane, and DCM UI.
- A running environment agent with at least one embedded or external SP and its
  required cluster or runtime.
- `curl`, `jq`, and the provider-specific tools used by the walkthrough.
- A disposable namespace, project, or resource prefix for test data.
- Disposable credentials or tokens required by the documented agent
  authentication flow; never record secret values in results.

Live tests must use disposable IDs and clean up created policies, catalog items,
instances, providers, and containers after execution.

## Execution Order

Run the automated checks first. Stop before live testing if the site cannot be
built or the documented release inputs cannot be resolved. Run live tests in the
order below because later workflows depend on earlier resources.

1. Repository and source inventory
2. Hugo build, formatting, spelling, and link checks
3. Local setup and health checks
4. CLI configuration and command discovery
5. Catalog item, policy, and instance walkthrough
6. Additional provider registration and placement behavior
7. User-guide CRUD and output examples
8. UI and troubleshooting checks
9. Enhancement rendering and cross-repository freshness
10. Published-site smoke validation

## Test Cases

### DOC-001: Release input and source inventory

**Type:** automated/review

**Steps:**

1. Resolve and record the commit for every release input.
2. Enumerate every page linked from the documentation section indexes.
3. Extract every external DCM repository, path, command, endpoint, resource
   kind, and provider name mentioned by the pages.
4. Compare the extracted inventory with the source-of-truth table above.

**Expected:** Every referenced repository and path exists at the recorded
revision, or the page explicitly labels it as a conceptual/example link.

### DOC-002: Site build and static quality

**Type:** automated

**Steps:**

1. Run `make build` from the repository root.
2. Run `make check-format`.
3. Run `make check-spell`.
4. Inspect generated output for Hugo errors, unresolved shortcodes, missing
   images, and unexpected draft or future-dated pages.
5. Check internal links and anchors in the generated site, including links
   generated by the enhancement content integration.

**Expected:** All commands pass; generated pages contain no broken internal
links, missing local assets, or build warnings that affect content.

### DOC-003: Local setup walkthrough

**Type:** live/manual

**Steps:**

1. Follow `Getting Started > Local Setup` from a clean disposable workspace.
2. Clone the documented control-plane and CLI repositories.
3. Start the documented core services and environment agent with the supported
   SP profile.
4. Run the documented `podman-compose ps`, control-plane health, agent health,
   and agent provider-list checks.
5. Build the CLI using the documented command and run `dcm version`.

**Expected:** Commands work as written, service names match the compose file,
the control-plane and agent health endpoints return success, provider discovery
uses the environment-agent API, and the CLI can reach the control plane.

### DOC-004: CLI configuration and discovery

**Type:** live/manual

**Steps:**

1. Verify the documented default control-plane URL and config path.
2. Exercise one configuration value from the file, environment, and command
   line, confirming the documented precedence.
3. Run representative commands with table, JSON, and YAML output.
4. Run the documented shell completion commands for the supported shells.
5. Confirm documented command names and flags using `dcm --help`, including
   `dcm agent list` and `dcm agent get` where documented.
6. Fail the test if any supported page still uses a removed `dcm sp provider`
   command.

**Expected:** Configuration, precedence, output formats, completion commands,
and command names match the current CLI specification and binary behavior.

### DOC-005: Catalog item workflow

**Type:** live/manual

**Steps:**

1. Follow `Create Small VM Catalog Item` with the documented YAML.
2. Create the item using the documented CLI command and optional ID.
3. Retrieve it in table, YAML, and JSON output.
4. Verify the item through the catalog-item API or control-plane state.
5. Repeat the corresponding User Guide list, filter, pagination, and delete
   examples where the release supports them.

**Expected:** The YAML schema is accepted, the created resource contains the
documented resource-scoped fields, all shown commands use valid flags, and
list/get/delete results describe the actual state.

### DOC-006: Placement policy workflow

**Type:** live/manual

**Steps:**

1. Follow `Create Placement Policy` using the documented policy file.
2. Create, list, get, update, and delete a disposable policy.
3. Exercise any documented filter, ordering, enabled-state, or merge-patch
   examples.
4. Confirm the policy selects an environment agent and is used by a subsequent
   instance placement test.

**Expected:** Policy field names, policy type values, CLI flags, merge-patch
semantics, `selected_agent` behavior, and placement results match the
control-plane and environment-agent APIs and runtime.

### DOC-007: Catalog instance and provider resource workflow

**Type:** live/manual

**Steps:**

1. Create an instance of the catalog item from DOC-005.
2. Follow the documented get and YAML output steps.
3. Verify the selected environment agent and wait for the SP resource to reach
   the documented state.
4. Verify the resource using the documented `dcm sp resource` command and API
   data.
5. Exercise rehydrate only when the release includes that capability and the
   page identifies the required provider state.
6. Delete the instance and verify cleanup in DCM, the environment agent, and the
   underlying SP runtime.

**Expected:** Resource identifiers used in later commands are actually returned
by earlier commands, asynchronous status wording is accurate, and cleanup
behavior matches the documentation.

### DOC-008: Additional agent and provider workflow

**Type:** live/manual

**Steps:**

1. Verify that the walkthrough identifies the environment agent as the standard
   registration and routing layer.
2. Follow any documented external-SP registration steps against the agent API.
3. Verify provider health through the agent provider API and agent registration
   through the control-plane agent API.
4. If multiple providers are documented, verify that the page explains the
   agent's one-provider-per-service-type constraint and provides a supported
   multi-agent alternative, or remove the unsupported workflow.

**Expected:** Provider registration, naming, health status, agent selection, and
routing behavior match the current environment-agent implementation and
deployment configuration.

### DOC-009: User Guide command coverage

**Type:** live/manual

**Steps:**

1. For Agents, Service Types, Catalog Items, Catalog Item Instances, Policies,
   and Service Provider Resources, run at least one list and get example.
2. Run every documented optional flag at least once: filters, pagination, output
   format, ordering, and `--show-deleted` where applicable.
3. Compare displayed field names and statuses with API responses and the CLI
   specification.

**Expected:** Every command block is executable with valid resource IDs and the
prose accurately describes the result. Agent commands and API boundaries match
the standard architecture. Examples must not depend on placeholder IDs being
present in a clean environment.

### DOC-010: UI and troubleshooting validation

**Type:** live/manual

**Steps:**

1. Follow the UI page to locate the documented route or Backstage path.
2. Confirm the page loads and exposes the documented DCM navigation.
3. Introduce a disposable service failure and follow the troubleshooting
   commands for logs, status, and restart.
4. Restore the service and verify the health check recovers.

**Expected:** The route, navigation labels, compose service names, log commands,
restart command, and recovery expectations match the deployed stack.

### DOC-011: Enhancement content validation

**Type:** automated/manual

**Steps:**

1. Verify the configured enhancement base URL resolves at the recorded
   enhancements revision.
2. Compare the enhancement index links with the source repository directory.
3. Build with network access and inspect representative enhancement pages for
   title, headings, code blocks, images, and internal links.
4. Verify rewritten relative and root-absolute enhancement links resolve to the
   recorded GitHub source revision and return success.
5. Verify that generated pages contain no site-root `/enhancements/*.md` links.
6. Verify a missing or malformed remote enhancement fails visibly rather than
   silently publishing an empty page.

**Expected:** The index and fetched content represent the intended source
revision and render consistently in a production build. Cross-references use
valid source URLs rather than broken generated-site paths.

### DOC-012: Environment-agent authentication and registration

**Type:** live/manual

**Steps:**

1. Follow the authentication guide from a clean environment-agent setup.
2. Verify an unauthenticated or invalidly authenticated registration/request is
   rejected.
3. Verify a correctly authenticated agent or SP registration succeeds.
4. Confirm the resulting agent and provider state through the documented
   control-plane and environment-agent APIs.
5. Confirm that credentials are supplied through the documented configuration
   mechanism and are not embedded in commands, YAML, logs, or result artifacts.

**Expected:** Authentication behavior, endpoint ownership, configuration names,
and registration results match the environment-agent and control-plane
implementations.

### DOC-013: Release regression and freshness review

**Type:** review

**Steps:**

1. Diff the documentation against the previous release validation results.
2. Re-run workflows affected by changed commands, API paths, schemas, images,
   provider setup, or enhancement links.
3. Search for stale versions, archived repositories, old service names, obsolete
   command prefixes, and placeholder values presented as real IDs.
4. Confirm PR or release changes affecting the docs have corresponding
   validation evidence.
5. Record known limitations and intentionally untested provider-specific paths.

**Expected:** Changed documentation has corresponding validation evidence, and
known service/application documentation drift is recorded as follow-up work.

### DOC-014: Published-site smoke validation

**Type:** live/manual

**Steps:**

1. Record the deployed workflow run, commit, and published site URL.
2. Open representative getting-started, user-guide, and enhancement pages from
   the published URL rather than the local Hugo server.
3. Verify the published HTML contains the expected environment-agent,
   resource-scoped schema, and rewritten enhancement links.
4. Request each representative rewritten external link and verify success.
5. Confirm no page still serves stale provider-only commands or site-root
   enhancement Markdown links.

**Expected:** The deployed site matches the validated source revision and the
release-critical workflows and links work after deployment.

## Acceptance Criteria

A documentation release passes when:

- DOC-001 and DOC-002 pass with the release inputs recorded.
- DOC-003 through DOC-010 pass for the supported release deployment profile, or
  an exception identifies the unavailable dependency and owner.
- The standard environment-agent registration and routing boundary is documented
  and exercised successfully.
- Current catalog resources, placement policies, and agent selection are covered
  by passing live workflows.
- No supported page contains a removed `dcm sp provider` command.
- DOC-011 and DOC-012 pass for the release inputs recorded.
- DOC-013 has no unresolved high-severity discrepancy.
- DOC-014 passes against the deployed published site, not only a local build.
- Every failed test has a reproducible command, source revision, observed
  result, expected result, and disposition.

Severity guidance:

- **High:** prevents setup, corrupts a resource, sends a user to a missing
  endpoint, or describes a command that cannot run in the supported profile.
- **Medium:** a workflow step or expected result is materially inaccurate but
  has a documented workaround.
- **Low:** wording, formatting, stale example data, or non-blocking link issue.

Documentation that is generally behind current service or application
repositories should be tracked as a separate resynchronization effort with its
own source inventory and release scope; it does not pass this gate merely by
being identified.

## Evidence And Results

Create a dated result file beside this plan using the following structure:

```text
# DCM Documentation Release Validation - YYYY-MM-DD

Documentation revision:
Control-plane revision:
CLI revision:
Utilities revision:
Environment-agent revision:
Enhancements revision:
Published site URL:
Published deployment run/commit:
Environment:
Operator:

| Test case | Result | Evidence | Issue |
| --- | --- | --- | --- |
| DOC-001 | PASS/FAIL/BLOCKED | command, URL, or artifact | link or `-` |

## Discrepancies

## Exceptions

## Cleanup confirmation
```

Attach command output, rendered URLs, screenshots for UI checks, and the
resolved source revisions. Keep findings in Markdown; do not automatically
update Jira.
