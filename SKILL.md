---
name: self-mirror-guideline
description: Use when writing or reviewing code for agent-operated systems that need searchable self-awareness comments, Mermaid adjacency links, GitNexus dependency evidence, and structured error/warning/info events.
---

# Self Mirror Guideline

Use this skill when code or design must be maintained by agents across context switches, runtime bridges, Docker materialization, MCP tools, or team orchestration.

## One Sentence

Make every important code node, dependency edge, and runtime failure searchable and explainable to future agents.

## Working Loop

1. Identify the node id.
2. Identify feature, prev, next, deps, and evidence.
3. Link the node to Mermaid architecture or add a small Mermaid block in the design doc.
4. Use `@sm` comments only at module boundaries, exported functions, protocol adapters, materialization boundaries, and failure paths.
5. Emit error/warning/info through the Self Mirror event contract.

## Output Layers

- L1: one sentence naming the main node and main risk.
- L2: three sentences: node, dependency evidence, next action.
- L3: five sentences: add failure path and verification.
- L4: full design or code details.

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

- `references/comment-markers.md`: `@sm` marker rules.
- `references/error-warning-info-contract.md`: structured event contract.
- `references/mermaid-adjacency-comments.md`: Mermaid-to-code adjacency rules.
- `references/gitnexus-mermaid-workflow.md`: GitNexus + Mermaid workflow.
- `examples/typescript-self-mirror.ts`: TypeScript example.
- `schemas/self-mirror-event.schema.json`: JSON Schema for events.

## Review Questions

- Can another agent find this node with `rg '@sm:node'`?
- Can GitNexus verify the dependency named in `@sm:deps`?
- Does the error explain what feature it protects, not only what failed?
- Is the Mermaid graph in the design doc consistent with the code anchors?

