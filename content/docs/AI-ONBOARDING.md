# Using the DCM AI Prompt for Architecture Exploration

**Purpose:** The DCM AI prompt (`DCM-AI-PROMPT.md`) is a 5,772-line comprehensive knowledge base covering every architectural decision, capability, data structure, and cross-reference in DCM. When loaded into Claude or another capable LLM, it enables conversational exploration of the architecture — faster than reading documentation.

---

## How to Use It

### Option 1: Claude.ai (Recommended)

1. Go to [claude.ai](https://claude.ai)
2. Start a new conversation
3. Attach `DCM-AI-PROMPT.md` as a file (drag and drop, or use the attachment button)
4. Ask your question

The prompt stays active for the entire conversation. You can ask follow-up questions without re-uploading.

### Option 2: Claude Projects

1. Create a Project in Claude
2. Add `DCM-AI-PROMPT.md` to the Project's knowledge base
3. Every conversation in that Project automatically has the full architecture context

This is the best option for ongoing use — the prompt is always available without re-uploading.

### Option 3: Other LLMs

The prompt works with any LLM that supports large context windows (128K+ tokens). Upload `DCM-AI-PROMPT.md` as context. The prompt is plain Markdown with no tool-specific formatting.

---

## Example Questions

### Understanding a concept
> "How does the override model work?"  
> → 2-paragraph answer explaining the 5 mechanisms with severity ordering

> "What's the difference between Internal and External policy evaluation?"  
> → Comparison of the two modes with when to use each

> "What happens when a sovereignty policy blocks a request?"  
> → Full flow: POLICY_BLOCKED state, consumer guidance, resolution options

### Finding specific details
> "What are the 6 provider types and when would I use each?"  
> → Table with type, capability, data direction, and example

> "What SQL tables exist and what's in each one?"  
> → Full schema overview with 18 tables, their purposes, and RLS details

> "What events does the system emit during a VM provision?"  
> → Ordered list of events with payloads from intent through realization

### Implementation guidance
> "I'm building a new service provider. What endpoints do I need to implement?"  
> → Provider contract requirements by level (Level 1: basic, Level 2: discovery, Level 3: full)

> "How do I write a GateKeeper policy that blocks VMs over 16 CPUs for a specific tenant?"  
> → Example Rego policy with match conditions, output schema, and test cases

> "How does the three-tier app example work end to end?"  
> → Full walkthrough with YAML payloads, dependency resolution, and binding field injection

### Cross-cutting questions
> "Does the architecture cover [specific capability] from PR #50?"  
> → Yes/no with specific doc references and capability IDs

> "What would change if we added a new provider type?"  
> → Schema migration needed, contract extension points, capabilities to declare

---

## What the Prompt Covers

The prompt contains 125 sections organized into these areas:

| Area | Sections | What's in it |
|------|----------|-------------|
| Foundational Abstractions | 0-3 | Data, Provider, Policy — the three pillars |
| Data Model | 4-14 | Four states, layers, entities, relationships, groups |
| Control Plane | 15-16 | 9 services, pipeline flow, request routing |
| Providers | 16-22 | 6 types, contracts, naturalization, discovery |
| Policy | 17, 23-28 | 8 types, evaluation model, overrides, templates |
| Audit & Security | 29-35 | Merkle tree, stage signing, governance matrix, zero trust |
| API Specifications | 36-40 | Consumer API (74 paths), Admin API (61 paths), Provider Callback |
| Capabilities | 41 | 331 capabilities across 39 domains |
| SQL Schema | 42 | 18 tables with column definitions |
| Event Catalog | 43 | 109 events across 23 domains |
| Implementation | 44-50 | Deployment, profiles, test framework |

---

## Tips

- **Be specific.** "How does policy evaluation work?" gets a better answer than "Tell me about policies."
- **Ask for examples.** "Show me the YAML payload at each stage of a VM provision" gets concrete data structures.
- **Ask for cross-references.** "Which docs should I read for provider development?" gets a prioritized list.
- **Ask for comparisons.** "How does this differ from Crossplane / Kessel / KRO?" gets an informed comparison.
- **Ask implementation questions.** "What Go interfaces would a new service provider need?" gets code-level guidance.

---

## Where to Find the Prompt

- **DCM repo:** `architecture/ai/DCM-AI-PROMPT.md`
- **Website:** Published at `dcm-project.github.io/docs/architecture/ai/DCM-AI-PROMPT/`
- **Examples repo:** Copied into `docs/DCM-AI-PROMPT.md` for reference
