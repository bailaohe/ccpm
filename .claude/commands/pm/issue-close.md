---
allowed-tools: Bash, Read, Write, LS
---

# Issue Close

Mark an issue as complete and close it on Git Service.

## Usage
```
/pm:issue-close <issue_number> [completion_notes]
```

## Instructions

### 0. Initialize Git Service Detection

```bash
# Load Git service functions (环境变量已通过 settings.local.json 自动加载)
source .claude/scripts/git/git-service-functions.sh

echo "Using $GIT_SERVICE with $GIT_CLI_TOOL CLI"

# Check repository protection
check_repository_protection
```

### 1. Find Local Task File

First check if `.claude/epics/*/$ARGUMENTS.md` exists (new naming).
If not found, search for task file with `gitsrv:.*issues/$ARGUMENTS` in frontmatter (old naming).
If not found: "❌ No local task for issue #$ARGUMENTS"

### 2. Update Local Status

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update task file frontmatter:
```yaml
status: closed
updated: {current_datetime}
```

### 3. Update Progress File

If progress file exists at `.claude/epics/{epic}/updates/$ARGUMENTS/progress.md`:
- Set completion: 100%
- Add completion note with timestamp
- Update last_sync with current datetime

### 4. Close Issue

Add completion comment and close using unified interface:
```bash
# Create completion comment
completion_comment="✅ Task completed

$ARGUMENTS

---
Closed at: {timestamp}"

# Close the issue with comment
git_close_issue "$ARGUMENTS" "$completion_comment"
```

### 5. Update Epic Task List

Check the task checkbox in the epic issue:

```bash
# Get epic name from local task file path
epic_name={extract_from_path}

# Get epic issue number from epic.md
epic_issue=$(grep 'gitsrv:' .claude/epics/$epic_name/epic.md | grep -oE '[0-9]+$')

if [ ! -z "$epic_issue" ]; then
  # Get current epic body using unified interface
  git_view_issue "$epic_issue" | jq -r '.body' > /tmp/epic-body.md
  
  # Check off this task
  sed -i "s/- \[ \] #$ARGUMENTS/- [x] #$ARGUMENTS/" /tmp/epic-body.md
  
  # Update epic issue using unified interface
  git_edit_issue "$epic_issue" "" "/tmp/epic-body.md" "" ""
  
  echo "✓ Updated epic progress on $GIT_SERVICE"
fi
```

### 6. Update Epic Progress

- Count total tasks in epic
- Count closed tasks
- Calculate new progress percentage
- Update epic.md frontmatter progress field

### 7. Output

```
✅ Closed issue #$ARGUMENTS
  Local: Task marked complete
  Git Service: Issue closed & epic updated
  Epic progress: {new_progress}% ({closed}/{total} tasks complete)
  
Next: Run /pm:next for next priority task
```

## Important Notes

Follow `/rules/frontmatter-operations.md` for updates.
Follow `/rules/git-service-operations.md` for Git Service commands.
Always sync local state before Git Service.
