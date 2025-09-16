---
allowed-tools: Bash, Read, Write, LS
---

# Issue Reopen

Reopen a closed issue.

## Usage
```
/pm:issue-reopen <issue_number> [reason]
```

## Instructions

### 1. Find Local Task File

Search for task file with `gitsrv:.*issues/$ARGUMENTS` in frontmatter.
If not found: "❌ No local task for issue #$ARGUMENTS"

### 2. Update Local Status

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update task file frontmatter:
```yaml
status: open
updated: {current_datetime}
```

### 3. Reset Progress

If progress file exists:
- Keep original started date
- Reset completion to previous value or 0%
- Add note about reopening with reason

### 4. Reopen on Git Service

```bash
# Prepare reopen comment
echo "🔄 Reopening issue

Reason: $ARGUMENTS

---
Reopened at: {timestamp}" > /tmp/reopen-comment.md

# Reopen issue with comment using unified interface
git_reopen_issue $ARGUMENTS "$(cat /tmp/reopen-comment.md)"

# Clean up
rm /tmp/reopen-comment.md
```

### 5. Update Epic Progress

Recalculate epic progress with this task now open again.

### 6. Output

```
🔄 Reopened issue #$ARGUMENTS
  Reason: {reason_if_provided}
  Epic progress: {updated_progress}%
  
Start work with: /pm:issue-start $ARGUMENTS
```

## Important Notes

Preserve work history in progress files.
Don't delete previous progress, just reset status.
