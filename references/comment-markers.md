# Comment Markers

Self Mirror comments are search anchors, not prose documentation.

## Marker Namespace

Use `@sm:` for source comments and `@self-mirror:` for Markdown frontmatter or long-form docs.

Required markers for boundary nodes:

```ts
// @sm:node <stable-node-id>
// @sm:feature <feature-id>
// @sm:prev <upstream-node-id>
// @sm:next <downstream-node-id>
// @sm:deps <dependency-id>[,<dependency-id>]
// @sm:evidence <command-or-artifact>
```

Optional markers:

```ts
// @sm:why <one-line-design-reason>
// @sm:risk <known-risk-id>
// @sm:owner <package-or-team>
// @sm:contract <schema-or-interface-name>
// @sm:gbrain <page-slug>
// @sm:gitnexus <symbol-or-query>
```

## Placement Rules

Place markers at:

- exported functions/classes that are architecture nodes;
- adapters between runtimes, protocols, or trust boundaries;
- materialization boundaries that write files, Docker assets, credentials, or tool config;
- failure paths whose error must be understandable after context compaction.

Do not place markers at:

- obvious local variable assignments;
- private helpers with no architectural meaning;
- comments that only restate the next line of code.

## Stable Id Format

Use lowercase dotted ids:

```text
<system>.<domain>.<verb-or-node>
```

Examples:

- `adocker.package.resolve`
- `adocker.materializer.link-volume`
- `legion.launch-plan.build`
- `runtime.codex.bridge`
- `runtime.claude.mcp-http`
- `evidence.self-mirror.emit`

## Search Contract

Every new subsystem must answer these commands:

```bash
rg '@sm:node' .
rg '@sm:feature agent-docker.materialize' .
rg 'ADK-MAT-' .
```

