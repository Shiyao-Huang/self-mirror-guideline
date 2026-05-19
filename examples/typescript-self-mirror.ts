export type SelfMirrorEvent = {
  level: 'error' | 'warning' | 'info';
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

export class SelfMirrorError extends Error {
  readonly event: SelfMirrorEvent;

  constructor(event: SelfMirrorEvent) {
    super(`${event.code}: ${event.reason}`);
    this.name = 'SelfMirrorError';
    this.event = event;
  }
}

export function emitSelfMirrorEvent(event: SelfMirrorEvent): void {
  const line = JSON.stringify(event);
  if (event.level === 'error') {
    console.error(line);
    return;
  }
  if (event.level === 'warning') {
    console.warn(line);
    return;
  }
  console.info(line);
}

type AgentPackageManifest = {
  runtime?: {
    entrypoint?: string;
  };
};

// @sm:node adocker.materializer.validate-manifest
// @sm:feature agent-docker.materialize
// @sm:prev adocker.package.resolve
// @sm:next adocker.materializer.link-volume
// @sm:deps agent-package.manifest,self-mirror-event
// @sm:evidence pnpm test packages/adocker-materializer
export function validateManifest(manifest: AgentPackageManifest): string {
  emitSelfMirrorEvent({
    level: 'info',
    code: 'ADK-MAT-000',
    feature: 'agent-docker.materialize',
    purpose: 'Confirm manifest validation started before local materialization',
    reason: 'The materializer must know the runtime entrypoint before linking files or credentials',
    location: {
      file: 'packages/adocker-materializer/src/manifest.ts',
      symbol: 'validateManifest',
    },
    dependency: ['agent-package.manifest'],
  });

  const entrypoint = manifest.runtime?.entrypoint;
  if (!entrypoint) {
    throw new SelfMirrorError({
      level: 'error',
      code: 'ADK-MAT-001',
      feature: 'agent-docker.materialize',
      purpose: 'Create a runnable local Agent Docker environment',
      reason: 'Package manifest is missing runtime.entrypoint',
      location: {
        file: 'packages/adocker-materializer/src/manifest.ts',
        symbol: 'validateManifest',
      },
      dependency: ['agent-package.manifest'],
      remediation: 'Add runtime.entrypoint or select a complete package version.',
      evidence: ['pnpm test packages/adocker-materializer'],
    });
  }

  if (!entrypoint.startsWith('./')) {
    emitSelfMirrorEvent({
      level: 'warning',
      code: 'ADK-MAT-002',
      feature: 'agent-docker.materialize',
      purpose: 'Keep package entrypoints relocatable inside Docker materialization',
      reason: 'runtime.entrypoint is not a relative path',
      location: {
        file: 'packages/adocker-materializer/src/manifest.ts',
        symbol: 'validateManifest',
      },
      dependency: ['docker-volume-linker'],
      remediation: 'Prefer a relative entrypoint such as ./bin/start-agent.',
    });
  }

  return entrypoint;
}

