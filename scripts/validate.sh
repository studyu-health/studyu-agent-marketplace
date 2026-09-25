#!/usr/bin/env bash
set -euo pipefail

failed=0
skills=0
mcps=0

for file in plugins/*/.apm/skills/*/SKILL.md; do
  [ -f "$file" ] || continue
  skills=$((skills + 1))

  if [ "$(wc -l < "$file")" -gt 500 ]; then
    echo "$file: must be 500 lines or fewer" >&2
    failed=1
  fi
  if tr '\\\n' '  ' < "$file" | grep -Eiq '(curl|wget)[^|]*\|[[:space:]]*(ba)?sh'; then
    echo "$file: forbidden network pipe to shell" >&2
    failed=1
  fi
done

for file in plugins/dart/apm.yml plugins/sonarqube/apm.yml; do
  [ -f "$file" ] || continue
  mcps=$((mcps + 1))
  name=${file#plugins/}
  name=${name%/apm.yml}

  if ! grep -qx "name: $name" "$file" || ! grep -qx "    - name: $name" "$file"; then
    echo "$file: package and MCP names must match its directory" >&2
    failed=1
  fi
  if ! grep -qx '      registry: false' "$file"; then
    echo "$file: self-defined MCP server must set registry: false" >&2
    failed=1
  fi
  if grep -Eq '(/Users/|/home/)' "$file"; then
    echo "$file: absolute user path" >&2
    failed=1
  fi
  if grep -oE '\$\{[A-Za-z0-9_]+\}' "$file" | grep -qvE '^\$\{STUDYU_[A-Z0-9_]+\}$'; then
    echo "$file: secrets must use \${STUDYU_<NAME>} placeholders" >&2
    failed=1
  fi
done

for source in THIRD_PARTY/*; do
  [ -d "$source" ] || continue
  for record in LICENSE SOURCE; do
    if [ ! -f "$source/$record" ]; then
      echo "$source: missing $record" >&2
      failed=1
    fi
  done
done

if [ "$failed" -ne 0 ]; then
  exit 1
fi

echo "OK: $skills skills, $mcps MCP servers"
