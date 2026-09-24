#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
usage() {
  echo "Usage: bash bin/install.sh skills <target-dir>" >&2
  echo "       bash bin/install.sh mcp <target-dir> [server...]" >&2
  echo "       bash bin/install.sh all <target-dir>" >&2
  exit 2
}
[ "$#" -ge 2 ] || usage
mode=$1
target=$2
shift 2
case "$mode" in skills|mcp|all) ;; *) usage ;; esac
[ "$#" -eq 0 ] || [ "$mode" = mcp ] || usage
[ -d "$target" ] || { echo "target not found: $target" >&2; exit 2; }
cd "$target"

install_skills() {
  if ! command -v npx >/dev/null 2>&1; then
    echo "Warning: npx not found; agent skills not installed. Install Node >= 22.20 and re-run." >&2
  elif [ -f skills-lock.json ]; then
    if ! DISABLE_TELEMETRY=1 npx --yes skills@1.7.0 experimental_install; then
      echo "Warning: agent skills could not be installed. Check marketplace access and re-run." >&2
    fi
  elif ! DISABLE_TELEMETRY=1 npx --yes skills@1.7.0 add studyu-health/studyu-agent-marketplace --skill '*' --agent universal -y; then
    echo "Warning: agent skills could not be installed. Check marketplace access and re-run." >&2
  fi
  if [ -f skills-lock.json ] && command -v jq >/dev/null 2>&1; then
    while IFS= read -r key; do
      [ -f ".agents/skills/$key/SKILL.md" ] || echo "Warning: skill $key is missing after install." >&2
    done < <(jq -r '.skills | keys[]' skills-lock.json)
  fi
  mkdir -p .claude
  if [ -d .claude/skills ] && [ ! -L .claude/skills ]; then
    find .claude/skills -mindepth 1 -maxdepth 1 -type l -delete
    rmdir .claude/skills 2>/dev/null || echo "Warning: .claude/skills contains files; move them and re-run." >&2
  fi
  if [ ! -L .claude/skills ] && [ -d .agents/skills ]; then
    ln -s ../.agents/skills .claude/skills
  fi
}

install_mcp() {
  command -v jq >/dev/null 2>&1 || { echo "jq required" >&2; return 1; }
  local names=() available
  if [ "$#" -eq 0 ]; then
    while IFS= read -r name; do names+=("$name"); done < <(jq -r '.mcpServers | keys[]' "$root/.mcp.example.json")
  else names=("$@"); fi
  available=$(printf '%s ' "$root"/mcps/*/.mcp.json); available=${available//$root\/mcps\//}; available=${available//\/.mcp.json/}; available=${available% }
  local files=() name
  for name in "${names[@]}"; do
    if [ ! -f "$root/mcps/$name/.mcp.json" ]; then
      echo "unknown server: $name" >&2; echo "available: $available" >&2; return 1
    fi
    files+=("$root/mcps/$name/.mcp.json")
  done
  local selection
  selection=$(mktemp)
  jq -s 'reduce .[] as $f ({}; . * $f)' "${files[@]}" > "$selection"
  local added=() present=()
  if [ ! -f .mcp.json ]; then
    cp "$selection" .mcp.json
    added=("${names[@]}")
  else
    if ! jq -e . .mcp.json >/dev/null 2>&1; then
      rm -f "$selection"
      echo ".mcp.json is not valid JSON; not changed." >&2
      return 1
    fi
    for name in "${names[@]}"; do
      if jq -e --arg name "$name" '.mcpServers[$name] != null' .mcp.json >/dev/null; then present+=("$name"); else added+=("$name"); fi
    done
    local tmp
    tmp=$(mktemp .mcp.json.XXXXXX)
    jq -s --slurpfile sel "$selection" '.[0] * {mcpServers: ($sel[0].mcpServers + (.[0].mcpServers // {}))}' .mcp.json > "$tmp"
    mv "$tmp" .mcp.json
  fi
  rm -f "$selection"
  [ "${#added[@]}" -eq 0 ] || echo "added: ${added[*]}"
  [ "${#present[@]}" -eq 0 ] || echo "already present: ${present[*]}"
  echo "Claude Code, VS Code, and OMP read .mcp.json (Claude Code asks for approval on first use). Cursor: copy the entries to .cursor/mcp.json."
}

case "$mode" in
  skills) install_skills ;;
  mcp) install_mcp "$@" ;;
  all)
    names=$(jq -r '.mcpServers | keys | join(",")' "$root/.mcp.example.json")
    printf 'Enable StudyU MCP servers (%s) in .mcp.json? [y/N] ' "$names"
    read -r ans || ans=""
    install_skills
    case "$ans" in
      [yY]*) install_mcp || echo "Warning: MCP servers not configured." >&2 ;;
      *) echo "Skipped MCP servers. Enable later: bash $root/bin/install.sh mcp $target" ;;
    esac
    ;;
esac
