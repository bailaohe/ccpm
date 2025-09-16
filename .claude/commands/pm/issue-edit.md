---
allowed-tools: Bash, Read, Write, LS
---

# Issue Edit

Edit issue details locally and on Git service.

## Usage
```
/pm:issue-edit <issue_number>
```

## Instructions

### 1. Get Current Issue State

```bash
# Get from Git service using unified interface
git_view_issue $ARGUMENTS

# Find local task file
# Search for file with gitsrv:.*issues/$ARGUMENTS
```

### 2. Interactive Edit

Ask user what to edit:
- Title
- Description/Body
- Labels
- Acceptance criteria (local only)
- Priority/Size (local only)

### 3. Update Local File

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update task file with changes:
- Update frontmatter `name` if title changed
- Update body content if description changed
- Update `updated` field with current datetime

### 4. Update Git Service

If title changed:
```bash
git_edit_issue $ARGUMENTS "{new_title}"
```

If body changed:
```bash
git_edit_issue $ARGUMENTS "" "{updated_task_file}"
```

If labels changed:
```bash
git_edit_issue $ARGUMENTS "" "" "{new_labels}"
```

### 5. Output

```
✅ Updated issue #$ARGUMENTS
  Changes:
    {list_of_changes_made}
  
Synced to $GIT_SERVICE: ✅
```

## Important Notes

Always update local first, then Git service.
Preserve frontmatter fields not being edited.
Follow `/rules/frontmatter-operations.md`.
