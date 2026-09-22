---
name: release-bugzilla
description: Cut a new BMO (mozilla/bmo) release - bump VERSION in Bugzilla.pm, PR, wait for CI, squash merge, tag release-X, and watch the deploy workflow. Argo CD and smoke tests stay manual.
disable-model-invocation: true
argument-hint: "[version, e.g. 20260922.1 - defaults to today's date]"
allowed-tools: Bash, Read
---

# BMO release

Cut a new Bugzilla release. `$ARGUMENTS` optionally overrides the version.

## Rules

- **Stop on any failure.** Report the failing command and its output. Do not retry
  pushes or merges, and do not improvise workarounds.
- **Confirm before each outward-facing step** (marked 🔒): show exactly what will run,
  then wait for the user's "yes".
- Commit message, PR title, and squash subject are exactly `Bumped version to <VERSION>`
  with **no body and no trailers** (no Co-Authored-By). This matches past releases.
- Use lightweight tags (`git tag <name>`, never `-a`), matching past releases.
- Show progress as `Step N of 15` at each step.

## Step 1 - Preflight

1. Confirm the repo: `gh repo view --json nameWithOwner -q .nameWithOwner` must print
   `mozilla/bmo`. The `origin` URL may say `mozilla-bteam/bmo`, which GitHub redirects.
   Either is fine.
2. `git branch --show-current` must be `master`.
3. `git status --porcelain --untracked-files=no` must be empty. Untracked files are fine.

## Step 2 - Update master

```bash
git fetch origin --tags
git merge --ff-only origin/master
```

If the fast-forward fails, stop. Local master has diverged and the user must resolve it.

## Step 3 - Pick the version

- If `$ARGUMENTS` is set, use it as `VERSION`. It must match `^[0-9]{8}\.[0-9]+$`.
- Otherwise, `DATE=$(date +%Y%m%d)` and start at `N=1`. Increment `N` while either
  `git tag -l "release-$DATE.$N"` or `git ls-remote --heads origin "$DATE.$N"` returns
  something. `VERSION=$DATE.$N`.
- Show the current version (`grep -n 'our \$VERSION' Bugzilla.pm`) and the new one.
  Continue without waiting for confirmation.

## Step 4 - Branch, bump, commit

```bash
git checkout -b "$VERSION"
sed -i "s/^our \$VERSION = '[^']*';/our \$VERSION = '$VERSION';/" Bugzilla.pm
grep -n 'our \$VERSION' Bugzilla.pm   # verify it shows the new version
git add Bugzilla.pm
```

Do **not** commit it yourself. The user's commit hooks (simplify-guard and the
Conventional Commits type check) reject this message. Ask the user to run it
themselves in the prompt and wait for them to say it's done:

```
! git commit -m "Bumped version to <VERSION>"
```

Then check that `git log -1 --format='%s%n---body:%b(end)'` shows the exact subject
with an empty body, and `git diff HEAD~1 --stat` shows only `Bugzilla.pm | 2 +-`.

## Step 5 - 🔒 Push the branch

```bash
git push origin "$VERSION"
```

## Step 6 - Open the PR

```bash
gh pr create --repo mozilla/bmo --base master --head "$VERSION" \
  --title "Bumped version to $VERSION" --body ""
```

Record the PR number and show the PR URL.

## Step 7 - Wait for CI

CI can take longer than the Bash timeout. Run it in the background and wait for the
completion notification:

```bash
gh pr checks <PR> --repo mozilla/bmo --watch --fail-fast
```

If this exits non-zero, list the failing checks with their links, then stop.

## Step 8 - 🔒 Squash merge

`--subject` replaces the default `... (#PR)` title, so the PR number is not appended.
`--admin` is required: `master` branch protection demands an approving review, and
the user merges release PRs with admin rights. Say that the merge uses `--admin`
when asking for confirmation.

```bash
gh pr merge <PR> --repo mozilla/bmo --squash --admin \
  --subject "Bumped version to $VERSION" --body ""
```

## Step 9 - Pull the merged commit

```bash
git checkout master
git pull --ff-only origin master
git log -1 --format=%s   # must be exactly: Bumped version to $VERSION
grep -n 'our \$VERSION' Bugzilla.pm   # must show $VERSION
```

If either check fails, stop. Do not tag the wrong commit.

The auto-mode permission classifier may deny this step (as "Merge Without Review")
after an `--admin` merge. If it does, do not work around it. Ask the user to run:

```
! git checkout master && git pull --ff-only origin master && git log -1 --format='%s%n---body:%b(end)' && grep -n 'our \$VERSION' Bugzilla.pm
```

Then verify the output they paste back and continue.

## Step 10 - Tag

```bash
git tag "release-$VERSION"
```

## Step 11 - 🔒 Push the tag

This starts the `BMO Deployment` workflow (`.github/workflows/deploy.yml`).

```bash
git push origin "release-$VERSION"
```

If the auto-mode classifier denies the push, ask the user to run
`! git push origin release-<VERSION>` and continue once it succeeds.

## Step 12 - Watch the deploy build

Poll until the run appears (it can take ~30s), then watch it in the background:

```bash
gh run list --repo mozilla/bmo --workflow deploy.yml --branch "release-$VERSION" \
  --limit 1 --json databaseId,status,url
gh run watch <RUN_ID> --repo mozilla/bmo --exit-status
```

If it fails, show the run URL and the failing job, then stop.

## Steps 13-15 - Hand off (manual, the user does these)

Print this checklist and stop:

1. **Argo CD:** confirm stage picked up the new image and is healthy.
2. **Smoke test:** https://bugzilla.allizom.org
3. **Argo CD:** manually sync production to the new image.

Finish with a summary: version, PR URL, deploy run URL, tag name.

## Resuming after a partial run

If invoked with a `VERSION` that is already partly released, detect what is done and
skip ahead. Say which steps are skipped.

- Remote branch exists (`git ls-remote --heads origin $VERSION`) → skip steps 4-5.
- PR exists (`gh pr list --repo mozilla/bmo --head $VERSION --state all`) → skip step 6.
  If it is merged, also skip steps 7-8.
- Tag exists on the remote (`git ls-remote --tags origin release-$VERSION`) → skip to
  step 12.
