#!/usr/bin/env python3
"""Install and verify the all-in-one Self Mirror stack."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
from pathlib import Path
from typing import Any


def skill_root() -> Path:
    return Path(__file__).resolve().parents[1]


def default_codex_home() -> Path:
    return Path.home() / ".codex"


def load_dependencies() -> dict[str, Any]:
    path = skill_root() / "dependencies.json"
    return json.loads(path.read_text(encoding="utf-8"))


def check_command(command: list[str]) -> dict[str, Any]:
    if not shutil.which(command[0]):
        return {"ok": False, "command": command, "reason": "missing executable"}
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=20, check=False)
    except Exception as exc:  # pragma: no cover - defensive installer boundary
        return {"ok": False, "command": command, "reason": str(exc)}
    return {
        "ok": result.returncode == 0,
        "command": command,
        "returncode": result.returncode,
        "stdout": result.stdout.strip()[:2000],
        "stderr": result.stderr.strip()[:2000],
    }


def find_local_skill(name: str, skills_root: Path) -> Path | None:
    candidates = [
        skills_root / name,
        skill_root() / "vendor" / name,
        skill_root().parent / name,
        skill_root().parent / ".system" / name,
        Path.home() / ".codex" / "skills" / name,
        Path.home() / ".claude" / "skills" / name,
    ]
    for candidate in candidates:
        if (candidate / "SKILL.md").exists():
            return candidate
    return None


def copy_skill(source: Path, target: Path) -> str:
    if target.exists():
        return "already-installed"
    if not source.exists():
        return "missing-source"
    shutil.copytree(source, target, symlinks=True)
    return "installed"


def verify_codeflow(skills_root: Path) -> dict[str, Any]:
    script = skills_root / "codeflow" / "scripts" / "analyze-local.mjs"
    if not script.exists():
        return {"ok": False, "reason": "missing CodeFlow analyzer", "path": str(script)}
    return check_command(["node", str(script), str(skill_root()), "--format", "summary"])


def verify_mermaid_architect(skills_root: Path) -> dict[str, Any]:
    script = skills_root / "mermaid-architect" / "scripts" / "merge_graph.py"
    if not script.exists():
        return {"ok": False, "reason": "missing mermaid-architect merge_graph.py", "path": str(script)}
    return check_command(["python3", "-m", "py_compile", str(script)])


def main() -> int:
    parser = argparse.ArgumentParser(description="Install/verify Self Mirror stack dependencies.")
    parser.add_argument("--codex-home", type=Path, default=default_codex_home())
    parser.add_argument("--check-only", action="store_true")
    args = parser.parse_args()

    skills_root = args.codex_home.expanduser() / "skills"
    deps = load_dependencies()
    report: dict[str, Any] = {
        "install_root": str(skills_root),
        "skills": [],
        "tools": [],
        "checks": [],
    }

    for skill in deps.get("skills", []):
        name = skill["name"]
        target = skills_root / name
        source = find_local_skill(name, skills_root)
        status = "already-installed" if (target / "SKILL.md").exists() else "missing"
        if status == "missing" and source and not args.check_only:
            status = copy_skill(source, target)
        report["skills"].append({
            "name": name,
            "required": bool(skill.get("required", True)),
            "status": status,
            "source": str(source) if source else None,
            "target": str(target),
        })

    for tool in deps.get("tools", []):
        command = str(tool.get("check") or f"{tool['name']} --version").split()
        result = check_command(command)
        result["name"] = tool["name"]
        result["required"] = bool(tool.get("required", True))
        report["tools"].append(result)

    report["checks"].append({"name": "self-mirror skill", "ok": (skill_root() / "SKILL.md").exists()})
    report["checks"].append({"name": "mermaid-architect", **verify_mermaid_architect(skills_root)})
    report["checks"].append({"name": "codeflow", **verify_codeflow(skills_root)})

    failed = []
    failed.extend(item for item in report["skills"] if item["required"] and item["status"] not in {"already-installed", "installed"})
    failed.extend(item for item in report["tools"] if item["required"] and not item["ok"])
    failed.extend(item for item in report["checks"] if not item["ok"])
    report["ok"] = not failed

    print(json.dumps(report, indent=2, ensure_ascii=False, sort_keys=True))
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
