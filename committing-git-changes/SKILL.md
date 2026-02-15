---
name: committing-git-changes
description: Use this skill when preparing a Git commit from current working tree changes, auto-generating a commit message, confirming or editing it, and pushing to a remote. This includes staging changes, summarizing diffs, prompting for yes or edit, and running git push for the confirmed commit.
---

# Committing Git Changes

Create a commit from the current working tree, show a generated commit message for confirmation or edits, and push to the remote once the user confirms.

# Core Approach

1. Verify the repo has changes to commit.
2. Stage all changes.
3. Generate a commit message from the status summary.
4. Confirm or edit the message in the terminal.
5. Commit and push only after confirmation.

# Step-by-Step Instructions

## 1. Verify changes

Check the working tree before staging.

- `git status --porcelain`
- If empty, stop and report there is nothing to commit.

## 2. Stage and summarize

Stage all changes and show a short summary.

- `git add -A`
- `git diff --cached --stat`

## 3. Generate, confirm, and push

Use the helper script to generate a commit message, prompt for edits, and push when approved.

```bash
node ./scripts/git-commit-and-push.js
```

The script will:
- Print detected changes and staged summary
- Propose a commit message based on file changes
- Let the user edit the message in the terminal
- Commit and push when the user confirms

# Examples

## Example 1: Commit current changes

**User Query**: "git add/commit/push all current changes"

**Approach**:
1. Run the helper script
2. Confirm or edit the commit message
3. Let the script push

**Complete Commands:**
```bash
node ./scripts/git-commit-and-push.js
```

**Expected Outcome**: Changes are staged, committed with a confirmed message, and pushed.

# CLI Tools to Leverage

- `git` - status, add, commit, and push
- `node` - run the helper script

# Validation Checklist

- [ ] `git status -sb` shows a clean working tree
- [ ] `git log -1 --stat` shows the new commit
- [ ] `git push` completed without errors

# Supporting Files

- `./scripts/git-commit-and-push.js` - Generates the commit message, prompts for confirmation, and pushes
- `./package.json` - Sets the module type for the script
