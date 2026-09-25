# StudyU Agent Marketplace

![StudyU Bazaar: Nofi, the StudyU mascot, wearing a fez and holding a lantern in an ornate Istanbul-style bazaar, under a "StudyU Bazaar" sign with the Hagia Sophia in the background](docs/images/studyu-bazaar-hero.jpg)

StudyU skills, MCP servers, prompts, agents, instructions, and hooks for APM-supported agent harnesses.

## Install APM

```bash
brew install apm
```

See [APM installation options](https://microsoft.github.io/apm/getting-started/installation/) for pip, curl, WinGet, and Scoop.

## Install Packages

Add the marketplace once:

```bash
apm marketplace add studyu-health/studyu-agent-marketplace
```

Add packages to a repository's `apm.yml`:

```yaml
name: your-project
version: 1.0.0
targets: [claude, copilot, cursor, codex, gemini, grok-build, opencode, windsurf, kiro, antigravity, hermes, agent-skills]
dependencies:
  apm:
    - name: studyu-skills
      marketplace: studyu-agent-marketplace
      version: ^0.1.0
    - name: dart
      marketplace: studyu-agent-marketplace
      version: ^0.1.0
```

Install the declared packages:

```bash
apm install
```

Commit `apm.yml`, `apm.lock.yaml`, and the generated harness configuration. Do not commit `apm_modules/`.

After the first release tag exists, use direct, tag-pinned dependencies instead
of the catalog when a project needs an exact source ref:

```yaml
dependencies:
  apm:
    - studyu-health/studyu-agent-marketplace/plugins/studyu-skills#v0.1.0
    - studyu-health/studyu-agent-marketplace/plugins/dart#v0.1.0
```

## Harnesses

| Harness | APM target | Skills | MCP configuration |
|---|---|---|---|
| Claude Code | `claude` | `.claude/skills/` | `.mcp.json` |
| GitHub Copilot | `copilot` | `.agents/skills/` | `.github/mcp.json` |
| Cursor | `cursor` | `.agents/skills/` | `.cursor/mcp.json` |
| Codex | `codex` | `.agents/skills/` | `.codex/config.toml` |
| OpenCode | `opencode` | `.agents/skills/` | `opencode.json` |
| Gemini | `gemini` | `.agents/skills/` | `.gemini/settings.json` |
| Windsurf | `windsurf` | `.agents/skills/` | Windsurf MCP configuration |
| Kiro | `kiro` | `.kiro/skills/` | `.kiro/settings/mcp.json` |
| Grok Build | `grok-build` | `.grok/skills/` | MCP unsupported |
| Antigravity | `antigravity` | `.agents/skills/` | `.agents/mcp_config.json` |
| Hermes | `hermes` | `.agents/skills/` | Hermes MCP configuration |
| OMP | `claude,agent-skills` | `.agents/skills/` | `.mcp.json` |
| Pi | `claude,agent-skills` | `.agents/skills/` | `.mcp.json` through `pi-mcp-adapter` |

OMP and Pi both load Agent Skills from `.agents/skills/`. Install `pi-mcp-adapter` once before Pi uses an MCP server:

```bash
pi install npm:pi-mcp-adapter
```

## Packages

| Package | Contents | Use |
|---|---|---|
| `studyu-skills` | Five StudyU development skills | Add to a project `apm.yml` |
| `dart` | Dart and Flutter MCP server via FVM | Add to a Flutter project `apm.yml` |
| `sonarqube` | SonarQube MCP server | Install globally after authenticating to SonarQube |

Install SonarQube for a developer's supported global harnesses:

```bash
apm install -g sonarqube@studyu-agent-marketplace --target claude,codex,copilot
```

OpenCode and Cursor use project MCP configuration. Add `sonarqube` to that project's `apm.yml` when a team needs it.

## Add A Resource

Copy `templates/package` to `plugins/<package-name>`, update its `apm.yml`, and add the package to the root `marketplace.packages` list.

- Skills: `.apm/skills/<skill-name>/SKILL.md`
- Prompts: `.apm/prompts/<name>.prompt.md`
- Instructions: `.apm/instructions/<name>.instructions.md`
- Agents: `.apm/agents/<name>.agent.md`
- Hooks: `.apm/hooks/<name>.json`
- MCP servers: `dependencies.mcp` in the package `apm.yml`

Run these commands before opening a pull request:

```bash
bash scripts/validate.sh
apm marketplace check
apm pack --offline
apm audit --ci
```

Commit the generated `.claude-plugin/marketplace.json` and `.agents/plugins/marketplace.json` files when they change.
