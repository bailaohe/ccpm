---
allowed-tools: Bash, Read, Write, LS
---

# Sync

Full bidirectional sync between local and Git service.

## Usage
```
/pm:sync [epic_name]
```

If epic_name provided, sync only that epic. Otherwise sync all.

## Instructions

### 1. Pull from Git Service

Get current state of all issues:
```bash
# Get all epic and task issues using unified interface
git_list_issues "epic" "all" > /tmp/epic-issues.json
git_list_issues "task" "all" > /tmp/task-issues.json
```

### 2. Update Local from Git Service

For each Git service issue:
- Find corresponding local file by issue number
- Compare states:
  - If Git service state newer (updatedAt > local updated), update local
  - If Git service closed but local open, close local
  - If Git service reopened but local closed, reopen local
- Update frontmatter to match Git service state

### 3. Push Local to Git Service

For each local task/epic:
- If has Git service URL but issue not found, it was deleted - mark local as archived
- If no Git service URL, create new issue (like epic-sync)
- If local updated > Git service updatedAt, push changes:
  ```bash
  git_edit_issue {number} "" "{local_file}"
  ```

### 4. Handle Conflicts

If both changed (local and Git service updated since last sync):
- Show both versions
- Ask user: "Local and $GIT_SERVICE both changed. Keep: (local/$GIT_SERVICE/merge)?"
- Apply user's choice

### 5. Update Sync Timestamps

Update all synced files with last_sync timestamp.

### 6. Output

```
🔄 Sync Complete

Pulled from $GIT_SERVICE:
  Updated: {count} files
  Closed: {count} issues
  
Pushed to $GIT_SERVICE:
  Updated: {count} issues
  Created: {count} new issues
  
Conflicts resolved: {count}

Status:
  ✅ All files synced
  {or list any sync failures}
```

## Important Notes

Follow `/rules/git-service-operations.md` for Git service commands.
Follow `/rules/frontmatter-operations.md` for local updates.
Always backup before sync in case of issues.
