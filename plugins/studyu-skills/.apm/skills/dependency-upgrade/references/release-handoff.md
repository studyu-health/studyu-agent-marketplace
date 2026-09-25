# Dependency Upgrade Release Handoff

## Stop Conditions

Stop and request a decision or remediation when the clean worktree, approved
SDK plan, migration notes, solver result, required validation, required native
host, required native approval, or generated diff is missing or invalid. Keep
the exact failure output. Do not bypass a failure with an override, downgrade,
skipped check, or unrelated refactor.

## Versioning

After required checks pass, commit only approved dependency changes with a
Conventional Commit. Preview Melos versioning before mutating:

```bash
printf 'n\n' | fvm exec melos version --all --no-git-tag-version
```

Review the proposed versions and changelogs, then run:

```bash
fvm exec melos version --all --no-git-tag-version --yes
git log --oneline --decorate -n 5
```

Use the actual Melos version commit to identify only the package manifests whose
versions changed. Never create or push tags before merge.

## Pull Request And Production Release

Follow the `pull-request` skill after versioning. Push only the branch:

```bash
git push -u origin HEAD
```

After a pull request merges to `main`, use its GitHub metadata and
`origin/main` history to identify the resulting commit. At that exact commit,
verify the approved package names and versions. Before explicit production
release authorization, only show the required annotated tag and push commands;
do not run them. Never move or overwrite an existing tag.
