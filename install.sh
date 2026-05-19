#!/usr/bin/env bash
#
# self-mirror-guideline — one-line installer
# Usage:
#   curl -sfL https://raw.githubusercontent.com/Shiyao-Huang/self-mirror-guideline/main/install.sh | bash
#   curl -sfL https://raw.githubusercontent.com/Shiyao-Huang/self-mirror-guideline/main/install.sh | bash -s -- --uninstall
#
set -euo pipefail

REPO="${SELF_MIRROR_REPO:-https://github.com/Shiyao-Huang/self-mirror-guideline.git}"
SKILL_NAME="${SELF_MIRROR_SKILL_NAME:-self-mirror-guideline}"

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

CODEX_HOME="$(detect_codex_home)"
INSTALL_DIR="${SELF_MIRROR_INSTALL_DIR:-$CODEX_HOME/self-mirror-guideline}"
SKILLS_DIR="$CODEX_HOME/skills"
TARGET_DIR="$SKILLS_DIR/$SKILL_NAME"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
ok() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

copy_skill_bundle() {
  mkdir -p "$TARGET_DIR"
  cp "$INSTALL_DIR/SKILL.md" "$TARGET_DIR/SKILL.md"

  for dir in references examples schemas docs; do
    rm -rf "$TARGET_DIR/$dir"
    if [ -d "$INSTALL_DIR/$dir" ]; then
      cp -R "$INSTALL_DIR/$dir" "$TARGET_DIR/$dir"
    fi
  done
}

if [ "${1:-}" = "--uninstall" ]; then
  info "Uninstalling $SKILL_NAME..."
  rm -rf "$TARGET_DIR"
  ok "Removed skill: $TARGET_DIR"

  if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    ok "Removed install dir: $INSTALL_DIR"
  fi

  ok "$SKILL_NAME uninstalled."
  exit 0
fi

info "Codex home detected: $CODEX_HOME"
command -v git >/dev/null 2>&1 || error "git is required."

mkdir -p "$SKILLS_DIR"

if [ -d "$INSTALL_DIR/.git" ]; then
  info "Updating existing installation at $INSTALL_DIR..."
  git -C "$INSTALL_DIR" fetch --depth 1 origin
  git -C "$INSTALL_DIR" reset --hard origin/main
else
  info "Cloning $REPO to $INSTALL_DIR..."
  rm -rf "$INSTALL_DIR"
  git clone --depth 1 "$REPO" "$INSTALL_DIR"
fi

[ -f "$INSTALL_DIR/SKILL.md" ] || error "Missing SKILL.md in $INSTALL_DIR"

info "Installing skill bundle to $TARGET_DIR..."
copy_skill_bundle
ok "Skill installed: $SKILL_NAME"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  self-mirror-guideline installed successfully${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Restart Codex to use the skill:"
echo "  - $SKILL_NAME"
echo ""
echo "Installed files:"
echo "  - $TARGET_DIR/SKILL.md"
echo "  - $TARGET_DIR/references"
echo "  - $TARGET_DIR/examples"
echo "  - $TARGET_DIR/schemas"
echo ""
echo "To uninstall:"
echo "  curl -sfL https://raw.githubusercontent.com/Shiyao-Huang/self-mirror-guideline/main/install.sh | bash -s -- --uninstall"
