# APM Package Template

Copy this directory to `plugins/<package-name>/`.

- Put skills in `.apm/skills/<skill-name>/SKILL.md`.
- Put prompts in `.apm/prompts/<name>.prompt.md`.
- Put instructions in `.apm/instructions/<name>.instructions.md`.
- Put agents in `.apm/agents/<name>.agent.md`.
- Put hooks in `.apm/hooks/<name>.json`.
- Declare MCP servers in `dependencies.mcp` in `apm.yml`.

Add the package to the root `marketplace.packages` list, run `apm marketplace check`, then run `apm pack --offline` and commit the generated catalogs.
