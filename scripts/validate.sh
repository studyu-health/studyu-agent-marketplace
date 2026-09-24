#!/usr/bin/env bash
set -euo pipefail

failed=0
skills=0
mcps=0
for file in skills/*/SKILL.md; do
  [ -f "$file" ] || continue
  skills=$((skills + 1))
  dir=${file#skills/}; dir=${dir%/SKILL.md}
  fm=$(awk 'NR == 1 && $0 == "---" { in_fm=1; next } in_fm && $0 == "---" { closed=1; exit } in_fm { print } END { if (!closed) exit 1 }' "$file") || { echo "$file: missing frontmatter" >&2; failed=1; continue; }
  if [ -z "$fm" ]; then echo "$file: missing frontmatter" >&2; failed=1; continue; fi
  name=$(printf '%s\n' "$fm" | awk -F: '$1 == "name" { sub(/^[[:space:]]*/, "", $2); print $2; exit }')
  if [ "$name" != "$dir" ] || [ "${#name}" -gt 64 ] || ! [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then echo "$file: invalid name" >&2; failed=1; fi
  description=$(printf '%s\n' "$fm" | sed -n 's/^description:[[:space:]]*//p')
  description=${description#\"}; description=${description%\"}; description=${description#\'}; description=${description%\'}
  if [ -z "$description" ] || [ "${#description}" -gt 1024 ]; then echo "$file: description must be 1–1024 characters" >&2; failed=1; fi
  unknown=$(printf '%s\n' "$fm" | awk -F: 'NF && $1 !~ /^(name|description|license|compatibility|metadata|allowed-tools|argument-hint)$/ { print $1 }')
  if [ -n "$unknown" ]; then echo "$file: unknown frontmatter key: $unknown" >&2; failed=1; fi
  lines=$(wc -l < "$file" | tr -d ' ')
  if tr '\\\n' '  ' < "$file" | grep -Eiq '(curl|wget)[^|]*\|[[:space:]]*(ba)?sh'; then echo "$file: forbidden network pipe to shell" >&2; failed=1; fi
done
for file in mcps/*/.mcp.json; do
  [ -f "$file" ] || continue
  mcps=$((mcps + 1))
  name=${file#mcps/}; name=${name%/.mcp.json}
  if ! jq -e '.mcpServers | type == "object" and length == 1' "$file" >/dev/null; then echo "$file: must define exactly one server under mcpServers" >&2; failed=1; continue; fi
  key=$(jq -r '.mcpServers | keys[0]' "$file")
  if [ "$key" != "$name" ]; then echo "$file: server key must be $name" >&2; failed=1; fi
  if ! jq -e '[.mcpServers[] | select(has("url") and (has("type") | not))] | length == 0' "$file" >/dev/null; then echo "$file: remote server requires type" >&2; failed=1; fi
  if jq -r '.. | strings' "$file" | grep -Eq '(/Users/|/home/)'; then echo "$file: absolute user path" >&2; failed=1; fi
done
if [ ! -f .mcp.example.json ]; then echo ".mcp.example.json: missing" >&2; failed=1
else
  while IFS= read -r k; do
    if [ ! -f "mcps/$k/.mcp.json" ]; then echo ".mcp.example.json: $k has no catalog entry" >&2; failed=1
    elif ! jq -e --slurpfile c "mcps/$k/.mcp.json" --arg k "$k" '.mcpServers[$k] == $c[0].mcpServers[$k]' .mcp.example.json >/dev/null; then echo ".mcp.example.json: $k differs from mcps/$k/.mcp.json" >&2; failed=1
    fi
  done < <(jq -r '.mcpServers | keys[]' .mcp.example.json)
fi
if [ "$failed" -ne 0 ]; then exit 1; fi
echo "OK: $skills skills, $mcps mcps"
