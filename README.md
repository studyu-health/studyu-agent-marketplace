# StudyU Agent Marketplace

Shared StudyU agent skills and MCP servers, installed with [APM](https://github.com/microsoft/apm) into any harness it supports: Claude Code, OpenCode, GitHub Copilot, Codex, Cursor, and more. OMP and Pi pick up the same files because they read Claude Code's and the portable `.mcp.json` config; Pi needs [`pi-mcp-adapter`](https://github.com/nicobailon/pi-mcp-adapter) installed once (`pi install npm:pi-mcp-adapter`).

## Install APM

```bash
brew install apm
```

See [other install methods](https://microsoft.github.io/apm/getting-started/installation/) (pip, curl, WinGet, Scoop) if you are not on Homebrew.

## Use it in a repository

Add an `apm.yml` at the repository root:

```yaml
name: your-project
version: 1.0.0
targets: [claude, opencode, copilot, codex, cursor]
dependencies:
  apm:
    - studyu-health/studyu-agent-marketplace#v0.1.0
    - studyu-health/studyu-agent-marketplace/mcps/dart#v0.1.0
```

Then run:

```bash
apm install
```

This writes every skill to `.agents/skills/` and `.claude/skills/`, and configures the `dart` MCP server in `.mcp.json`, `opencode.json`, `.github/mcp.json`, `.codex/config.toml`, and `.cursor/mcp.json`. Commit `apm.yml` and the generated `apm.lock.yaml`; gitignore the deployed skill and MCP config files if you want agent setup to stay opt-in per developer (see StudyU's `setup.sh` for an example).

Declaring `targets:` makes the install reproducible across machines; omitting it lets APM auto-detect the harnesses already configured on each machine. See [Install MCP servers](https://microsoft.github.io/apm/consumer/install-mcp-servers/) for the target-gating rules.

### Install only some skills

```bash
apm install studyu-health/studyu-agent-marketplace --skill asd-ste100 --skill pull-request
```

The selection is persisted to `apm.yml`. Use `--skill '*'` to reset to the full set.

### `npx skills` still works

The skill layout (`skills/<name>/SKILL.md`) is the standard [agentskills.io](https://agentskills.io) convention, so it also installs with:

```bash
DISABLE_TELEMETRY=1 npx skills add studyu-health/studyu-agent-marketplace --skill '*'
```

Use this only when a target agent has no APM support. APM is the supported path for anything that also needs the MCP servers below.

## Skills

| Skill | What it does |
|---|---|
| `asd-ste100` | Rewrites technical text for clarity using STE100 principles. |
| `dependency-upgrade` | Guides Flutter, Dart, and package dependency upgrades. |
| `flutter-platform-regeneration` | Safely regenerates Flutter Android and iOS project files when required. |
| `manual-testing` | Creates prioritized manual QA checklists from a code change. |
| `pull-request` | Checks and structures pull requests before creation. |

## MCP servers

| Server | Package | Prerequisites |
|---|---|---|
| `dart` | `mcps/dart` | FVM; run from a repository with `.fvmrc`. |
| `sonarqube` | `mcps/sonarqube` | Opt-in, per developer (see below). `brew install --cask sonarqube-cli`; `sonar auth login -s https://sonar.cloud.studyu.health`; Docker running. |

`dart` is meant for every StudyU Flutter developer, so a consuming repo lists it directly in its `apm.yml` (see the example above).

`sonarqube` needs a per-developer login, so it is not listed in any repository's `apm.yml`. Each developer who wants it installs it into their own user-level agent configs:

```bash
apm install -g studyu-health/studyu-agent-marketplace/mcps/sonarqube#v0.1.0 --target claude,codex,copilot
```

This writes to `~/.claude.json`, `~/.codex/config.toml`, and `~/.copilot/mcp-config.json` (OMP reads the Claude Code file too). OpenCode and Cursor only read MCP config from the project, so `sonarqube` will not appear there from a global install; add it to a project's `apm.yml` instead if a whole team needs it there.

SonarSource's upstream Sonar skills use a source-available license that excludes AI interaction, so they are not redistributed here. See `THIRD_PARTY/sonarqube-agent-plugins/SOURCE`.

## Update and audit

```bash
apm update       # refresh dependencies to their latest allowed version, with a confirmation prompt
apm audit         # check deployed files for drift from apm.yml / apm.lock.yaml
```

## Contributing

Keep the boundary clear: a skill needs agent judgment and is triggered by a task. Always-true repo facts belong in that repo's `AGENTS.md` or `docs/`; unattended fixed-input commands belong in its `scripts/`. An MCP server whose binary lives in a repo stays there. For example, StudyU's `tools/studyu_mcp` is not moved here.

Keep each skill's frontmatter limited to `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`, and `argument-hint`, and keep frontmatter values ASCII-only. The name must match the directory and use lowercase letters, digits, and single hyphen separators. Keep `description` between 1 and 1024 characters. Keep `SKILL.md` bodies under 500 lines; put detail in `references/*.md` one level deep and name each file in the body as "read `references/x.md` when ...". Never include secrets. Third-party skills require `THIRD_PARTY/<source>/{LICENSE,SOURCE}` records.

Add each MCP server at `mcps/<name>/apm.yml`, with `name:` at the top of the file and on its single `dependencies.mcp` entry both matching the directory name. Mark it `registry: false` since it is self-defined. Use bare commands and pass secrets only through `${STUDYU_<NAME>}` environment references, never literal values. Run `bash scripts/validate.sh` before opening a PR.
