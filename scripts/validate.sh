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
  if printf '%s\n' "$fm" | LC_ALL=C grep -q '[^ -~]'; then echo "$file: frontmatter must be ASCII" >&2; failed=1; fi
  name=$(printf '%s\n' "$fm" | awk -F: '$1 == "name" { sub(/^[[:space:]]*/, "", $2); print $2; exit }')
  if [ "$name" != "$dir" ] || [ "${#name}" -gt 64 ] || ! [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then echo "$file: invalid name" >&2; failed=1; fi
  description=$(printf '%s\n' "$fm" | sed -n 's/^description:[[:space:]]*//p')
  description=${description#\"}; description=${description%\"}; description=${description#\'}; description=${description%\'}
  if [ -z "$description" ] || [ "${#description}" -gt 1024 ]; then echo "$file: description must be 1-1024 characters" >&2; failed=1; fi
  unknown=$(printf '%s\n' "$fm" | awk -F: 'NF && $1 !~ /^(name|description|license|compatibility|metadata|allowed-tools|argument-hint)$/ { print $1 }')
  if [ -n "$unknown" ]; then echo "$file: unknown frontmatter key: $unknown" >&2; failed=1; fi
  if tr '\\\n' '  ' < "$file" | grep -Eiq '(curl|wget)[^|]*\|[[:space:]]*(ba)?sh'; then echo "$file: forbidden network pipe to shell" >&2; failed=1; fi
done

command -v python3 >/dev/null 2>&1 || { echo "python3 is required to validate mcps/*/apm.yml" >&2; exit 1; }
for file in mcps/*/apm.yml; do
  [ -f "$file" ] || continue
  mcps=$((mcps + 1))
  name=${file#mcps/}; name=${name%/apm.yml}
  if ! python3 - "$file" "$name" <<'PYEOF'
import sys

import yaml

path, dirname = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        doc = yaml.safe_load(f)
except Exception as e:  # noqa: BLE001
    print(f"{path}: invalid YAML: {e}", file=sys.stderr)
    sys.exit(1)

if not isinstance(doc, dict):
    print(f"{path}: must be a mapping", file=sys.stderr)
    sys.exit(1)
if doc.get("name") != dirname:
    print(f"{path}: name must be {dirname}", file=sys.stderr)
    sys.exit(1)

mcp = (doc.get("dependencies") or {}).get("mcp")
if not isinstance(mcp, list) or len(mcp) != 1:
    print(f"{path}: dependencies.mcp must define exactly one server", file=sys.stderr)
    sys.exit(1)

entry = mcp[0]
if not isinstance(entry, dict) or entry.get("name") != dirname:
    print(f"{path}: mcp entry name must be {dirname}", file=sys.stderr)
    sys.exit(1)
if entry.get("registry") is not False:
    print(f"{path}: self-defined server must set registry: false", file=sys.stderr)
    sys.exit(1)
if entry.get("transport") == "stdio" and not entry.get("command"):
    print(f"{path}: stdio server requires command", file=sys.stderr)
    sys.exit(1)
if entry.get("transport") in ("http", "sse", "streamable-http") and not entry.get("url"):
    print(f"{path}: remote server requires url", file=sys.stderr)
    sys.exit(1)
PYEOF
  then failed=1; fi
  if grep -Eq '(/Users/|/home/)' "$file"; then echo "$file: absolute user path" >&2; failed=1; fi
  if grep -oE '\$\{[A-Za-z0-9_]+\}' "$file" | grep -qvE '^\$\{STUDYU_[A-Z0-9_]+\}$'; then
    echo "$file: secrets must use \${STUDYU_<NAME>} placeholders" >&2; failed=1
  fi
done

if [ ! -f apm.yml ]; then echo "apm.yml: missing at repo root" >&2; failed=1; fi

if [ "$failed" -ne 0 ]; then exit 1; fi
echo "OK: $skills skills, $mcps mcps"
