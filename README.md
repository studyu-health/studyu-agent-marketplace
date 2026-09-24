# StudyU Agent Marketplace

Shared StudyU agent skills for Claude Code, Codex, Cursor, Copilot, Gemini, and OMP.

## Install

From a repository root:

```bash
DISABLE_TELEMETRY=1 npx skills add hpi-studyu/studyu-agent-marketplace --skill '*' --agent universal claude-code -y
```

This writes `.agents/skills/`, `.claude/skills/` symlinks, and `skills-lock.json`. Commit only `skills-lock.json`; installed skill directories are generated files. Restore in a clone with `DISABLE_TELEMETRY=1 npx --yes skills@1.7.0 experimental_install`. Update with `npx skills update -p`, then commit the changed lock file.

This repository currently provides five StudyU skills. SonarSource's upstream Sonar skills use a source-available license that excludes AI interaction, so they are not redistributed here. See `THIRD_PARTY/sonarqube-agent-plugins/SOURCE` for details.

## MCP servers

No MCP templates are currently distributed. The upstream Sonar plugin is not redistributed because its license excludes external AI interaction. For the supported SonarQube plugin, use `/plugin install sonarqube@claude-plugins-official`.

## Contributions

Keep the boundary clear: a skill needs agent judgment and is triggered by a task. Always-true repo facts belong in that repo's `AGENTS.md` or `docs/`; unattended fixed-input commands belong in its `scripts/`. An MCP server whose binary lives in a repo stays there. For example, StudyU's `tools/studyu_mcp` is not moved here.

Keep each skill's frontmatter limited to `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`, and `argument-hint`. The name must match the directory and use lowercase letters, digits, and single hyphen separators. Keep `description` between 1 and 1024 characters. Keep `SKILL.md` bodies under 500 lines; put detail in `references/*.md` one level deep and name each file in the body as “read `references/x.md` when …”. Never include secrets. Pin MCP package versions (`pkg@x.y.z`). Third-party skills require `THIRD_PARTY/<source>/{LICENSE,SOURCE}` records.
