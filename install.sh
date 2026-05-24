#!/usr/bin/env bash
#
# self-mirror-guideline — one-line installer
#
# Install (Claude Code):
#   curl -sfL https://raw.githubusercontent.com/Shiyao-Huang/self-mirror-guideline/main/install.sh | bash
#
# Install (Codex):
#   SELF_MIRROR_TARGET=codex bash install.sh
#
# Install (both):
#   SELF_MIRROR_TARGET=all bash install.sh
#
# Uninstall:
#   curl -sfL https://raw.githubusercontent.com/Shiyao-Huang/self-mirror-guideline/main/install.sh | bash -s -- --uninstall
#
# Install a fork:
#   SELF_MIRROR_REPO=https://github.com/<owner>/self-mirror-guideline.git bash install.sh
#
set -euo pipefail

REPO="${SELF_MIRROR_REPO:-https://github.com/Shiyao-Huang/self-mirror-guideline.git}"
SKILL_NAME="${SELF_MIRROR_SKILL_NAME:-self-mirror-guideline}"
BRANCH="${SELF_MIRROR_BRANCH:-main}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()  { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ── Detection ────────────────────────────────────────────────

detect_claude_home() {
  if [ -n "${CLAUDE_HOME:-}" ]; then
    echo "$CLAUDE_HOME"
    return
  fi
  echo "$HOME/.claude"
}

detect_codex_home() {
  if [ -n "${CODEX_HOME:-}" ]; then
    echo "$CODEX_HOME"
    return
  fi
  local codex_bin
  codex_bin="$(command -v codex 2>/dev/null || true)"
  if [ -n "$codex_bin" ]; then
    local inferred
    inferred="$(dirname "$(dirname "$codex_bin")")/.codex"
    if [ -d "$inferred" ]; then
      echo "$inferred"
      return
    fi
  fi
  if [ -d "${XDG_CONFIG_HOME:-$HOME/.config}/codex" ]; then
    echo "${XDG_CONFIG_HOME:-$HOME/.config}/codex"
    return
  fi
  echo "$HOME/.codex"
}

has_claude() {
  [ -d "$(detect_claude_home)" ] || [ -n "${CLAUDE_HOME:-}" ]
}

has_codex() {
  [ -d "$(detect_codex_home)" ] || [ -n "${CODEX_HOME:-}" ]
}

resolve_targets() {
  local target="${SELF_MIRROR_TARGET:-}"
  local targets=()

  if [ "$target" = "claude" ]; then
    targets+=("claude")
  elif [ "$target" = "codex" ]; then
    targets+=("codex")
  elif [ "$target" = "all" ]; then
    targets+=("claude" "codex")
  else
    if has_claude; then targets+=("claude"); fi
    if has_codex; then targets+=("codex"); fi
  fi

  if [ ${#targets[@]} -eq 0 ]; then
    targets+=("claude")
  fi

  echo "${targets[*]}"
}

# ── Install / Uninstall logic ────────────────────────────────

clone_or_update() {
  local install_dir="$1"
  if [ -d "$install_dir/.git" ]; then
    info "Updating existing clone at $install_dir..."
    git -C "$install_dir" fetch --depth 1 origin "$BRANCH"
    git -C "$install_dir" reset --hard "origin/$BRANCH"
  else
    info "Cloning $REPO ($BRANCH) to $install_dir..."
    rm -rf "$install_dir"
    git clone --depth 1 --branch "$BRANCH" "$REPO" "$install_dir"
  fi
}

copy_skill_bundle() {
  local src="$1"
  local target_dir="$2"

  mkdir -p "$target_dir"
  cp "$src/SKILL.md" "$target_dir/SKILL.md"

  for dir in references examples schemas docs scripts vendor; do
    rm -rf "$target_dir/$dir"
    if [ -d "$src/$dir" ]; then
      cp -R "$src/$dir" "$target_dir/$dir"
    fi
  done

  for file in dependencies.json; do
    if [ -f "$src/$file" ]; then
      cp "$src/$file" "$target_dir/$file"
    fi
  done
}

install_to_claude() {
  local claude_home
  claude_home="$(detect_claude_home)"
  local skills_dir="$claude_home/skills"
  local target_dir="$skills_dir/$SKILL_NAME"

  mkdir -p "$skills_dir"
  copy_skill_bundle "$INSTALL_DIR" "$target_dir"
  ok "Claude Code skill installed: $target_dir"
}

install_to_codex() {
  local codex_home
  codex_home="$(detect_codex_home)"
  local skills_dir="$codex_home/skills"
  local target_dir="$skills_dir/$SKILL_NAME"

  mkdir -p "$skills_dir"
  copy_skill_bundle "$INSTALL_DIR" "$target_dir"
  ok "Codex skill installed: $target_dir"
}

uninstall_from_claude() {
  local claude_home
  claude_home="$(detect_claude_home)"
  local target_dir="$claude_home/skills/$SKILL_NAME"

  if [ -d "$target_dir" ]; then
    rm -rf "$target_dir"
    ok "Removed Claude Code skill: $target_dir"
  fi
}

uninstall_from_codex() {
  local codex_home
  codex_home="$(detect_codex_home)"
  local target_dir="$codex_home/skills/$SKILL_NAME"

  if [ -d "$target_dir" ]; then
    rm -rf "$target_dir"
    ok "Removed Codex skill: $target_dir"
  fi
}

# ── Main ─────────────────────────────────────────────────────

INSTALL_DIR="${SELF_MIRROR_INSTALL_DIR:-}"

if [ "${1:-}" = "--uninstall" ]; then
  info "Uninstalling $SKILL_NAME..."

  if [ -n "$INSTALL_DIR" ] && [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    ok "Removed clone: $INSTALL_DIR"
  fi

  uninstall_from_claude
  uninstall_from_codex

  ok "$SKILL_NAME uninstalled."
  exit 0
fi

command -v git >/dev/null 2>&1 || die "git is required."

# Resolve clone directory
if [ -z "$INSTALL_DIR" ]; then
  CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/self-mirror-guideline"
  INSTALL_DIR="$CACHE_DIR/repo"
fi

clone_or_update "$INSTALL_DIR"

[ -f "$INSTALL_DIR/SKILL.md" ] || die "Missing SKILL.md in $INSTALL_DIR"

# Resolve targets
targets="$(resolve_targets)"
info "Install targets: $targets"

for target in $targets; do
  case "$target" in
    claude) install_to_claude ;;
    codex)  install_to_codex  ;;
  esac
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  self-mirror-guideline installed successfully${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Installed to:"
for target in $targets; do
  case "$target" in
    claude) echo "  - Claude Code: $(detect_claude_home)/skills/$SKILL_NAME/" ;;
    codex)  echo "  - Codex:       $(detect_codex_home)/skills/$SKILL_NAME/" ;;
  esac
done
echo ""
echo "Restart Claude Code / Codex to use the skill."
echo ""
echo "To uninstall:"
echo "  curl -sfL https://raw.githubusercontent.com/Shiyao-Huang/self-mirror-guideline/main/install.sh | bash -s -- --uninstall"
