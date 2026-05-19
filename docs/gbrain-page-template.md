# gbrain Page Template

```yaml
---
type: project-guideline
project: agent-cli
topic: self-mirror-guideline
version: v1
---
```

# Self Mirror Guideline v1

## L1

Self Mirror makes code and runtime failures readable by future agents.

## Links

- `projects/agent-cli/adocker/project-mainline-context-v1`
- `projects/agent-cli/adocker/adocker-system-architecture-v1`

## Facts

- Code comments use `@sm` markers.
- Architecture relation lives in Mermaid.
- Runtime events use `SelfMirrorEvent`.
- GitNexus validates actual dependency shape.

## Evidence

```bash
rg '@sm:node' .
gitnexus query -r happy -l 10 "runClaude runCodex MCP bridge AgentBackend"
```

