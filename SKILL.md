---
name: self-mirror-guideline
description: All-in-one Self Mirror / Mirror Graph guideline for agent-operated systems. Use when work needs searchable self-awareness comments, Mermaid DAG/object graph design, GitNexus dependency evidence, CodeFlow impact evidence, interview-driven node ranking, structured error/warning/info events, and handoff-safe execution records.
version: 1.1.0
authors:
  - Shiyao-Huang
---

# Self Mirror Guideline

Use this skill when code or design must be maintained by agents across context switches, runtime bridges, Docker materialization, MCP tools, graph-driven planning, or team orchestration.

Self Mirror is the all-in-one entrypoint. It coordinates:

- Mirror comments and structured events.
- Mermaid / Mirror Graph design.
- GitNexus code relationship evidence.
- CodeFlow impact and architecture evidence.
- Interview-driven demand and node ranking.
- Agent handoff notes, iterations, and execution traces.

## One Sentence

Make every important intent, code node, dependency edge, rank decision, and runtime failure searchable, evidence-backed, and explainable to future agents.

## Three Sentences

1. Self Mirror records why a node matters, how it ranks, what it depends on, and how another agent can safely continue.
2. Mermaid / Mirror Graph models work as objects and edges; GitNexus and CodeFlow ground those edges in real code and repo impact.
3. Ranking comes from interview evidence, not internal preference: use scenario simulation only to prepare The Mom Test style one-on-one interviews.

## All-In-One Stack

```text
Self Mirror = intent + value + rank + graph + anchors + events + evidence
Mirror Graph = object graph + Mermaid render + blockers + ready nodes
GitNexus = definitions + callers + callees + flow evidence
CodeFlow = repo map + impact + ownership/churn + cross-repo contracts
Interview Evidence = user-world pain + workaround + severity + natural rank
```

Use `self-mirror-guideline` as the main skill when the user asks for "mirror", "all in one", "architecture", "rank", "handoff", "traceability", or "agent self-awareness". Use `mermaid-architect` as the graph execution subskill when object graph queries, ready nodes, blockers, or Mermaid DAG updates are needed.

## Installation Contract

Installing this skill should install or verify the full mirror stack:

- Skills:
  - `mermaid-architect`
  - `codeflow`
- CLI tools:
  - `gitnexus`
  - `node`
  - `python3`
- Bundled files:
  - `references/`
  - `examples/`
  - `schemas/`
  - `docs/`
  - `scripts/install_dependencies.py`
  - `dependencies.json`

After install, run:

```bash
python3 scripts/install_dependencies.py --check-only
```

If dependencies are missing and local sibling skill folders exist, run:

```bash
python3 scripts/install_dependencies.py
```

The installer must not pretend optional evidence tools exist. If GitNexus, CodeFlow, or Mermaid Graph tooling is missing, record a warning and say which evidence lane is degraded.

## Working Loop

1. Identify the intent: why this matters, who it serves, and what failure looks like if absent.
2. Identify the node id, feature, prev, next, deps, and evidence.
3. If work needs planning or coordination, create/update the Mirror Graph object node before implementation.
4. Use interview evidence to rank demand; use simulated users only to prepare interview hypotheses.
5. Use GitNexus to verify symbol-level dependency claims.
6. Use CodeFlow to verify repo-level impact, ownership/churn, and cross-repo contracts.
7. Link source anchors to Mermaid / Mirror Graph nodes.
8. Use `@sm` comments only at module boundaries, exported functions, protocol adapters, materialization boundaries, and failure paths.
9. Emit error/warning/info through the Self Mirror event contract.
10. Leave comments, iterations, evidence, and value-alignment notes for the next agent.

## Output Layers

- L1: one sentence naming the main node and main risk.
- L2: three sentences: node, value, dependency evidence, next action.
- L3: five sentences: add rank evidence, failure path, and verification.
- L4: full design or code details.

## Mirror Graph Protocol

When work has multiple nodes, dependency order, or sub-agent handoff risk, use a Mirror Graph:

```text
Object Graph = Node objects + Edge objects + Query functions + Evidence records
Mermaid = render(Object Graph)
```

The preferred truth source is:

```text
.mermaid/current/graph.json
```

Important nodes should include:

```json
{
  "id": "F-010",
  "title": "Implement graph query API",
  "layer": "F",
  "status": "todo",
  "intent": {
    "one_sentence": "Make graph execution explainable and safe across agent handoffs.",
    "beneficiary": "future agents, current user, reviewers",
    "failure_if_absent": "Agents can call tools correctly but still miss the deeper purpose."
  },
  "value": {
    "principles": ["traceability", "handoff safety", "truth before speed"],
    "non_goals": ["decorative graph output", "unverifiable execution claims"],
    "success_meaning": "Another agent can explain why this node matters before touching code."
  },
  "interview_evidence": [],
  "research_rank": {
    "rank": null,
    "confidence": "low",
    "sample_size": 0,
    "next_research": "Interview 10-20 relevant users or scenario roles."
  },
  "taste_judgement": {
    "main_tension": "Fast execution vs safe handoff.",
    "what_to_optimize": "Blocker correctness and explainability.",
    "what_to_reject": "Tool calls without purpose."
  },
  "comments": [],
  "iterations": [],
  "evidence": {
    "gitnexus": [],
    "codeflow": [],
    "tests": []
  },
  "mirror": {
    "node": "stable.dotted.node",
    "feature": "feature.id",
    "prev": [],
    "next": [],
    "deps": []
  }
}
```

Use `mermaid-architect` tooling when available:

```bash
python3 /Users/copizzah/.codex/skills/mermaid-architect/scripts/merge_graph.py --ready .mermaid/current/
python3 /Users/copizzah/.codex/skills/mermaid-architect/scripts/merge_graph.py --rank .mermaid/current/
python3 /Users/copizzah/.codex/skills/mermaid-architect/scripts/merge_graph.py --node F-010 .mermaid/current/
python3 /Users/copizzah/.codex/skills/mermaid-architect/scripts/merge_graph.py --validate .mermaid/current/
```

## Interview-Driven Rank

Do not rank nodes by internal taste alone. Rank by user-world evidence.

Protocol:

1. Simulate relevant user scenarios only to prepare interview hypotheses.
2. Run one-on-one, complete, professional interviews.
3. Use The Mom Test style questions: ask about past behavior and real workarounds, not future promises.
4. Avoid "would you use this", "do you like this", and "is this useful".
5. Ask "last time this happened, what did you do", "what did it cost", "who was affected", and "what workaround exists now".
6. Interview 10-20 relevant users or scenario roles before treating a rank as stable.
7. If sample size is below 10, mark rank confidence as low.

Rank record:

```json
{
  "interview_evidence": [
    {
      "id": "INT-001",
      "segment": "maintainer",
      "scenario": "handoff after context loss",
      "past_behavior": "Lost 40 minutes reconstructing why a task was marked ready.",
      "current_workaround": "Reads chat history and manually checks files.",
      "pain_severity": 5,
      "frequency": "weekly",
      "signals": ["repeated pain", "high recovery cost", "clear workaround"]
    }
  ],
  "research_rank": {
    "rank": 1,
    "confidence": "medium",
    "sample_size": 14,
    "why_ranked_here": "Repeated across 9/14 interviews with high recovery cost."
  }
}
```

## Marker Template

```ts
// @sm:node <stable-node-id>
// @sm:feature <feature-id>
// @sm:prev <upstream-node-id>
// @sm:next <downstream-node-id>
// @sm:deps <dependency-id>[,<dependency-id>]
// @sm:evidence <test-or-command>
```

## Event Template

```ts
{
  level: "error",
  code: "ADK-MAT-001",
  feature: "agent-docker.materialize",
  purpose: "Create a runnable local Agent Docker environment",
  reason: "Package manifest is missing runtime.entrypoint",
  location: {
    file: "packages/adocker-materializer/src/manifest.ts",
    symbol: "validateManifest"
  },
  remediation: "Add runtime.entrypoint or select a package version with a complete manifest."
}
```

## Reference Files

These files are bundled with the skill and provide detailed rules:

- `references/comment-markers.md`: `@sm` marker rules.
- `references/error-warning-info-contract.md`: structured event contract.
- `references/mermaid-adjacency-comments.md`: Mermaid-to-code adjacency rules.
- `references/gitnexus-mermaid-workflow.md`: GitNexus + Mermaid workflow.
- `examples/typescript-self-mirror.ts`: TypeScript example.
- `schemas/self-mirror-event.schema.json`: JSON Schema for events.

## Review Questions

- Can another agent find this node with `rg '@sm:node'`?
- Can GitNexus verify the dependency named in `@sm:deps`?
- Can CodeFlow explain the repo-level impact of the files touched by this node?
- If this node has priority, is the rank backed by interview evidence rather than internal preference?
- Does the error explain what feature it protects, not only what failed?
- Is the Mermaid / Mirror Graph object consistent with the code anchors?

## Global Principles

1. First name the intent, then the node, then the code.
2. Comments only mark searchable structural facts, never restate surface behavior.
3. Errors are not strings — errors are events with feature, purpose, location.
4. Mirror Graph lives in object graph/design docs; source code only gets stable anchors and short relations.
5. GitNexus discovers symbol dependencies; CodeFlow discovers repo impact; Mirror Graph orders execution; Self Mirror explains them into agent-actionable context.
6. Rank comes from interview evidence; simulated users only prepare the interview, they do not decide priority.

## Minimal Landing Standard

A new module must include at minimum:

- One intent/value statement for important nodes.
- One Mermaid / Mirror Graph node id.
- One `@sm:node` comment anchor.
- One `@sm:feature` ownership tag.
- One `@sm:evidence` verification command or evidence.
- One GitNexus or CodeFlow evidence command when dependencies or impact matter.
- Failure paths use structured `SelfMirrorEvent`.
