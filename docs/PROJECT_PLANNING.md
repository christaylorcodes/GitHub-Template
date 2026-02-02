# Project Planning and Task Coordination

This project uses GitHub Issues, Milestones, and labels as the single source of truth for all planning, task tracking, and coordination between contributors (human and AI).

No separate planning files, TODO lists, or tracking spreadsheets. If it is not in a GitHub Issue, it is not planned work.

## How It Works

```
Milestone           Issue               Label Flow
───────────         ─────               ──────────
"v2.0 Release"  ──► #42 Add auth     ► ai-ready
                    #43 Fix timeout       │
                    #44 Update docs       ▼
"Backlog"       ──► #50 Add caching   ai-in-progress  (agent claimed it)
                    #51 Improve perf      │
                                          ▼
                                      ai-review  (PR submitted)
                                          │
                                          ▼
                                      closed  (merged)
```

**Milestones** group related issues into releases or project phases.
**Issues** describe individual tasks with requirements and acceptance criteria.
**Labels** track the state of each task through a defined lifecycle.

## Milestones

Use GitHub Milestones to group issues into logical phases.

```powershell
# List milestones
gh api repos/{owner}/{repo}/milestones --jq '.[] | "\(.title) - \(.open_issues) open, \(.closed_issues) closed"'

# Create a milestone
gh api repos/{owner}/{repo}/milestones --method POST -f title="v2.0" -f description="Next major release"
```

### Guidelines

- **One milestone per release or initiative** — keep them focused
- **Use the description** to state the goal in one sentence
- **Close milestones** when all issues are resolved
- **No-milestone issues** are backlog — ideas without a committed timeline

## Labels

Labels drive the coordination workflow. They are the mechanism that prevents duplicate work and makes task state visible to everyone.

### Task Lifecycle Labels

| Label | Color | Meaning | Who sets it |
| ----- | ----- | ------- | ----------- |
| `ai-ready` | Green | Available — no one is working on it | Maintainer |
| `ai-in-progress` | Yellow | Claimed — an agent or contributor is actively working | Agent (on claim) |
| `ai-review` | Blue | PR submitted, awaiting human review | Agent (on PR) |
| `ai-blocked` | Red | Agent needs human input to proceed | Agent (when stuck) |

### Task Type Labels

| Label | Color | Meaning |
| ----- | ----- | ------- |
| `ai-task` | Violet | Issue is structured with acceptance criteria for AI agents |
| `good-first-issue` | Violet | Simple task suitable for any contributor |
| `enhancement` | Default | Feature request or improvement |
| `bug` | Default | Something is broken |

### Priority Labels

| Label | Color | Meaning |
| ----- | ----- | ------- |
| `priority-high` | Red | Address before other work |
| `priority-medium` | Yellow | Normal priority |
| `priority-low` | Green | Address when convenient |

### Setting Up Labels

Run the label initialization script to create all recommended labels:

```powershell
./Scripts/Initialize-Labels.ps1         # Create labels
./Scripts/Initialize-Labels.ps1 -DryRun # Preview without creating
```

## The Coordination Protocol

This is the core workflow that prevents duplicate work between multiple agents and contributors.

### Step 1: Find Work

```powershell
# AI-structured tasks ready for pickup
gh issue list --label ai-ready --state open

# Good starter tasks
gh issue list --label "good-first-issue" --state open

# Everything in a specific milestone
gh issue list --milestone "v2.0" --state open

# High priority items
gh issue list --label "priority-high" --state open
```

### Step 2: Claim the Issue

Before starting work, claim the issue. This is what prevents two agents from working on the same task.

```powershell
gh issue edit <number> --add-label ai-in-progress --remove-label ai-ready
```

After claiming, the issue no longer appears in `--label ai-ready` queries. Other agents will not pick it up.

### Step 3: Work on It

1. Create a feature branch: `git checkout -b feature/<number>-short-description`
2. Read the full issue body — requirements, acceptance criteria, files to modify
3. Implement and test (see [AGENTS.md](../AGENTS.md) for conventions)
4. Run `./Tests/test-local.ps1` — all checks must pass

### Step 4: Submit for Review

```powershell
# Push and open PR
git push -u origin feature/<number>-short-description
gh pr create --title "Add feature X" --body "Fixes #<number>"

# Update the issue label
gh issue edit <number> --add-label ai-review --remove-label ai-in-progress
```

The PR description must reference the issue number. Use `Fixes #<number>` to auto-close the issue on merge.

### Step 5: If Blocked

If you cannot complete the work, hand it back with context:

```powershell
gh issue comment <number> --body "Blocked: <description of what is needed>"
gh issue edit <number> --add-label ai-blocked --remove-label ai-in-progress
```

A maintainer or another agent will see the `ai-blocked` label and the comment explaining what is needed.

## Label State Machine

```
                    ┌─────────────┐
     Maintainer     │             │
     creates ──────►│  ai-ready   │
     issue          │             │
                    └──────┬──────┘
                           │
                    Agent claims
                           │
                    ┌──────▼──────┐
                    │             │
                    │ai-in-progress│
                    │             │
                    └──┬───────┬──┘
                       │       │
              PR opened│       │Stuck
                       │       │
                ┌──────▼──┐ ┌──▼────────┐
                │         │ │           │
                │ai-review│ │ai-blocked │
                │         │ │           │
                └────┬────┘ └─────┬─────┘
                     │            │
              Merged │     Resolved, back to
                     │            │
                ┌────▼────┐ ┌─────▼─────┐
                │         │ │           │
                │ closed  │ │ ai-ready  │
                │         │ │ (retry)   │
                └─────────┘ └───────────┘
```

## Creating Good Issues

### For AI Agents

Use the `ai_task` issue template. It provides structured sections that AI agents parse reliably:

- **Objective** — one sentence: what needs to happen
- **Context** — background, links to related code or docs
- **Requirements** — checkboxes: specific, testable items
- **Acceptance Criteria** — what "done" looks like (tests pass, analyzer clean, etc.)
- **Files to Modify** — scopes the work
- **Out of Scope** — prevents scope creep

```powershell
# Create from the command line (or use the GitHub web UI with the template)
gh issue create --title "Add retry logic to Invoke-ApiCall" \
  --label "ai-task,ai-ready" \
  --milestone "v2.0" \
  --body "$(cat <<'EOF'
## Objective
Add configurable retry logic with exponential backoff to Invoke-ApiCall.

## Requirements
- [ ] Add -MaxRetries parameter (default: 3)
- [ ] Add -RetryDelaySeconds parameter (default: 2)
- [ ] Implement exponential backoff (delay doubles each retry)
- [ ] Log each retry attempt with Write-Verbose
- [ ] Only retry on transient HTTP errors (408, 429, 500, 502, 503, 504)

## Acceptance Criteria
- [ ] All existing tests still pass
- [ ] New tests cover retry behavior
- [ ] PSScriptAnalyzer reports zero errors

## Files to Modify
- source/Private/Invoke-ApiCall.ps1
- Tests/Unit/Private/Invoke-ApiCall.Tests.ps1
EOF
)"
```

### For General Work

Bug reports and feature requests do not need the `ai-task` structure. Use the standard templates. Add `ai-ready` if you want an AI agent to pick it up.

### Backlog Items

Issues with no milestone are backlog. They represent ideas that are not committed to a timeline. To promote a backlog item:

```powershell
# Assign to a milestone
gh issue edit <number> --milestone "v2.0"

# Mark as ready for work
gh issue edit <number> --add-label ai-ready
```

## Querying Project Status

```powershell
# Overview: what is in progress right now?
gh issue list --label ai-in-progress --state open

# What is waiting for review?
gh issue list --label ai-review --state open

# What is blocked?
gh issue list --label ai-blocked --state open

# Milestone progress
gh api repos/{owner}/{repo}/milestones \
  --jq '.[] | "\(.title): \(.closed_issues)/\(.open_issues + .closed_issues) done"'

# Recent activity
gh issue list --state all --limit 10 --json number,title,state,updatedAt \
  --jq '.[] | "#\(.number) [\(.state)] \(.title)"'
```

## Multi-Agent Coordination

When multiple AI agents (or humans + agents) work on the same project:

1. **Labels are the lock.** An issue with `ai-in-progress` is taken. Query `ai-ready` to find unclaimed work.
2. **First claim wins.** If two agents claim simultaneously, the first PR wins. The second agent will see the conflict when pushing and should abandon their branch.
3. **Comments are the log.** Agents should comment on issues with progress notes, blockers, or decisions. This creates a visible history for all participants.
4. **PRs close issues.** Use `Fixes #<number>` in the PR description so the issue auto-closes on merge.

### Race Conditions

Two agents could theoretically read `ai-ready` before either updates the label. In practice this is rare for small teams. If it happens:

- The first PR to pass CI and get merged wins
- The second agent sees merge conflicts or a closed issue
- No work is lost — the second agent simply moves to the next issue

For larger teams, consider using GitHub's built-in issue assignment (`gh issue edit <number> --add-assignee @me`) as an additional coordination signal.

## Session Notes

Individual agents may keep ephemeral session notes in `.claude/plan.md` (gitignored). These are personal scratchpads, not shared state. Project-level context belongs in GitHub Issues, not in local files.

See [CLAUDE.md](../CLAUDE.md) for session state guidance.
