# StudyU Agent Marketplace

Shared agent skills and MCP server configs for StudyU development. Works with any client supported by `npx skills` and any MCP client that reads the portable `.mcp.json` format.

## Skills

| Skill | What it does | Install one |
|---|---|---|
| `asd-ste100` | Rewrites technical text for clarity using STE100 principles. | `npx skills add studyu-health/studyu-agent-marketplace --skill asd-ste100` |
| `dependency-upgrade` | Guides Flutter, Dart, and package dependency upgrades. | `npx skills add studyu-health/studyu-agent-marketplace --skill dependency-upgrade` |
| `flutter-platform-regeneration` | Safely regenerates Flutter Android and iOS project files when required. | `npx skills add studyu-health/studyu-agent-marketplace --skill flutter-platform-regeneration` |
| `manual-testing` | Creates prioritized manual QA checklists from a code change. | `npx skills add studyu-health/studyu-agent-marketplace --skill manual-testing` |
| `pull-request` | Checks and structures pull requests before creation. | `npx skills add studyu-health/studyu-agent-marketplace --skill pull-request` |

## Install skills

Install all skills with interactive agent selection:

```bash
npx skills add studyu-health/studyu-agent-marketplace
```

List available skills:

```bash
npx skills add studyu-health/studyu-agent-marketplace --list
```

Restore skills from a committed lock file:

```bash
npx skills experimental_install
```

Update installed skills, then commit `skills-lock.json`:

```bash
npx skills update -p
```

## MCP servers

| Server | Config | Prerequisites |
|---|---|---|
| `dart` | `mcps/dart/.mcp.json` | FVM; run from a repository with `.fvmrc`. |
| `sonarqube` | `mcps/sonarqube/.mcp.json` | `brew install --cask sonarqube-cli`; `sonar auth login -s https://sonar.cloud.studyu.health`; Docker running. |

`.mcp.example.json` is the set enabled for StudyU development.

## Install MCP servers

Clone the marketplace, then install selected servers into a repository:

```bash
git clone https://github.com/studyu-health/studyu-agent-marketplace.git
bash studyu-agent-marketplace/bin/install.sh mcp /path/to/repo [server...]
```

You can also copy a server entry from `mcps/<name>/.mcp.json` by hand.

| Client | Config location |
|---|---|
| Claude Code, VS Code, OMP | `<repo>/.mcp.json` |
| Cursor | `<repo>/.cursor/mcp.json` (same `mcpServers` shape) |

## Everything at once

Install skills and choose whether to add the StudyU MCP servers:

```bash
bash studyu-agent-marketplace/bin/install.sh all /path/to/repo
```

StudyU's `./setup.sh` runs this installer.

## Contributing

Keep the boundary clear: a skill needs agent judgment and is triggered by a task. Always-true repo facts belong in that repo's `AGENTS.md` or `docs/`; unattended fixed-input commands belong in its `scripts/`. An MCP server whose binary lives in a repo stays there. For example, StudyU's `tools/studyu_mcp` is not moved here.

Keep each skill's frontmatter limited to `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`, and `argument-hint`. The name must match the directory and use lowercase letters, digits, and single hyphen separators. Keep `description` between 1 and 1024 characters. Keep `SKILL.md` bodies under 500 lines; put detail in `references/*.md` one level deep and name each file in the body as “read `references/x.md` when …”. Never include secrets. Pin MCP package versions (`pkg@x.y.z`). Third-party skills require `THIRD_PARTY/<source>/{LICENSE,SOURCE}` records.

Add each MCP server at `mcps/<name>/.mcp.json` with exactly one server keyed `<name>`. Use bare commands, pin package versions (`pkg@x.y.z`), and pass secrets only through `${STUDYU_<NAME>}` environment references. Add it to `.mcp.example.json` only if every StudyU developer should get it. Run `bash scripts/validate.sh`.

SonarSource's agent-plugin skills are not vendored; see `THIRD_PARTY/sonarqube-agent-plugins/SOURCE`.
