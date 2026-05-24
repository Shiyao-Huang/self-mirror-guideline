#!/usr/bin/env python3
"""Install and verify mermaid-architect skill dependencies."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
from pathlib import Path
from typing import Any


REQUIRED_SKILLS = ("codeflow", "self-mirror-guideline")
REQUIRED_TOOLS = ("gitnexus", "node", "python3")


def skill_root() -> Path:
    return Path(__file__).resolve().parents[1]


def default_codex_home() -> Path:
    return Path.home() / ".codex"


def load_dependencies() -> dict[str, Any]:
    path = skill_root() / "dependencies.json"
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return {
        "skills": [{"name": name, "required": True} for name in REQUIRED_SKILLS],
        "tools": [{"name": name, "required": True} for name in REQUIRED_TOOLS],
    }


def copy_skill(source: Path, target: Path) -> str:
    if not source.exists():
        return "missing-source"
    if target.exists():
        return "already-installed"
    shutil.copytree(source, target, symlinks=True)
    return "installed"


def find_local_skill(name: str, install_root: Path) -> Path | None:
    candidates = [
        install_root / name,
        skill_root().parent / name,
        skill_root().parent / ".system" / name,
    ]
    for candidate in candidates:
        if (candidate / "SKILL.md").exists():
            return candidate
    return None


def check_command(command: list[str]) -> dict[str, Any]:
    executable = shutil.which(command[0])
    if not executable:
        return {"ok": False, "command": command, "reason": "missing executable"}
    try:
        result = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
            timeout=15,
        )
    except Exception as exc:  # pragma: no cover - defensive installer boundary
        return {"ok": False, "command": command, "reason": str(exc)}
    return {
        "ok": result.returncode == 0,
        "command": command,
        "returncode": result.returncode,
        "stdout": result.stdout.strip()[:2000],
        "stderr": result.stderr.strip()[:2000],
    }


def verify_codeflow(install_root: Path) -> dict[str, Any]:
    script = install_root / "codeflow" / "scripts" / "analyze-local.mjs"
    if not script.exists():
        return {"ok": False, "reason": "missing codeflow analyze-local.mjs", "path": str(script)}
    return check_command(["node", str(script), str(skill_root()), "--format", "summary"])


def verify_merge_graph() -> dict[str, Any]:
    script = skill_root() / "scripts" / "merge_graph.py"
    return check_command(["python3", "-m", "py_compile", str(script)])


def verify_package() -> dict[str, Any]:
    package_files = sorted(str(path) for path in (skill_root() / "mermaid_architect").glob("*.py"))
    if not package_files:
        return {"ok": False, "reason": "missing mermaid_architect package"}
    return check_command(["python3", "-m", "py_compile", *package_files])


def verify_upstream_bundle() -> dict[str, Any]:
    required = ["mermaid_architect", "graph-ui", "templates", "pyproject.toml", "README.md", "License"]
    missing = [name for name in required if not (skill_root() / name).exists()]
    return {"ok": not missing, "missing": missing}


def main() -> int:
    parser = argparse.ArgumentParser(description="Install mermaid-architect required skill dependencies.")
    parser.add_argument("--codex-home", type=Path, default=default_codex_home())
    parser.add_argument("--check-only", action="store_true")
    args = parser.parse_args()

    install_root = args.codex_home.expanduser() / "skills"
    deps = load_dependencies()
    report: dict[str, Any] = {"install_root": str(install_root), "skills": [], "tools": [], "checks": []}

    for skill in deps.get("skills", []):
        name = skill["name"]
        target = install_root / name
        source = find_local_skill(name, install_root)
        status = "already-installed" if (target / "SKILL.md").exists() else "missing"
        if status == "missing" and not args.check_only and source:
            status = copy_skill(source, target)
        report["skills"].append({
            "name": name,
            "required": bool(skill.get("required", True)),
            "status": status,
            "source": str(source) if source else None,
            "target": str(target),
        })

    for tool in deps.get("tools", []):
        name = tool["name"]
        check = str(tool.get("check") or f"{name} --version").split()
        result = check_command(check)
        result["name"] = name
        result["required"] = bool(tool.get("required", True))
        report["tools"].append(result)

    report["checks"].append({"name": "merge_graph.py", **verify_merge_graph()})
    report["checks"].append({"name": "mermaid_architect package", **verify_package()})
    report["checks"].append({"name": "upstream bundle", **verify_upstream_bundle()})
    if (install_root / "codeflow" / "SKILL.md").exists():
        report["checks"].append({"name": "codeflow", **verify_codeflow(install_root)})
    else:
        report["checks"].append({"name": "codeflow", "ok": False, "reason": "codeflow skill missing"})

    missing_required_skills = [
        item for item in report["skills"] if item["required"] and item["status"] not in {"already-installed", "installed"}
    ]
    missing_required_tools = [item for item in report["tools"] if item["required"] and not item["ok"]]
    failed_checks = [item for item in report["checks"] if not item["ok"]]
    report["ok"] = not missing_required_skills and not missing_required_tools and not failed_checks

    print(json.dumps(report, indent=2, ensure_ascii=False, sort_keys=True))
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
