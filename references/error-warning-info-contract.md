# Error / Warning / Info Contract

Agent-facing systems must not emit anonymous strings for important runtime events.

## Required Fields

```ts
type SelfMirrorEvent = {
  level: "error" | "warning" | "info";
  code: string;
  feature: string;
  purpose: string;
  reason: string;
  location: {
    file: string;
    symbol?: string;
    line?: number;
  };
  dependency?: string[];
  remediation?: string;
  evidence?: string[];
  causeCode?: string;
  traceId?: string;
};
```

## Code Format

Use project prefix + domain + number:

```text
ADK-MAT-001  Agent Docker materialization
ADK-RUN-001  Runtime bridge
ADK-CRED-001 Credential broker
ADK-CTX-001  Context budget / injection
ADK-MCP-001  MCP bridge
ADK-LEG-001  Legion orchestration
SMR-EVT-001  Self Mirror event system
```

## Level Semantics

- `info`: expected operational milestone that helps agents reconstruct flow.
- `warning`: recoverable condition, fallback, missing optional capability, degraded mode.
- `error`: failed invariant or unrecoverable step for the current node.

## Minimum Error Example

```ts
emitSelfMirrorEvent({
  level: "error",
  code: "ADK-MAT-001",
  feature: "agent-docker.materialize",
  purpose: "Create a runnable local Agent Docker environment",
  reason: "Package manifest is missing runtime.entrypoint",
  location: {
    file: "packages/adocker-materializer/src/manifest.ts",
    symbol: "validateManifest"
  },
  dependency: ["agent-package.manifest"],
  remediation: "Add runtime.entrypoint to the package manifest.",
  evidence: ["pnpm test packages/adocker-materializer"]
});
```

## Bad Pattern

```ts
throw new Error("Invalid manifest");
```

It does not tell an agent:

- what feature is protected;
- where the fault was detected;
- what dependency is broken;
- what to do next.

## Good Pattern

```ts
throw new SelfMirrorError({
  level: "error",
  code: "ADK-MAT-001",
  feature: "agent-docker.materialize",
  purpose: "Create a runnable local Agent Docker environment",
  reason: "Package manifest is missing runtime.entrypoint",
  location: {
    file: "packages/adocker-materializer/src/manifest.ts",
    symbol: "validateManifest"
  },
  remediation: "Add runtime.entrypoint or select a complete package version."
});
```

