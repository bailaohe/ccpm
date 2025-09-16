---
allowed-tools: Bash, Read, Write, LS
---

# Import

Import existing Git service issues into the PM system.

## Usage
```
/pm:import [--epic <epic_name>] [--label <label>]
```

Options:
- `--epic` - Import into specific epic
- `--label` - Import only issues with specific label
- No args - Import all untracked issues

## Instructions

### 1. Fetch Git Service Issues

```bash
# Get issues based on filters using unified interface
if [[ "$ARGUMENTS" == *"--label"* ]]; then
  git_list_issues "{label}" "all" > /tmp/filtered-issues.json
else
  git_list_issues "" "all" > /tmp/all-issues.json
fi
```

### 2. Identify Untracked Issues

For each Git service issue:
- Search local files for matching issue URL
- If not found, it's untracked and needs import

### 3. Categorize Issues

Based on labels:
- Issues with "epic" label → Create epic structure
- Issues with "task" label → Create task in appropriate epic
- Issues with "epic:{name}" label → Assign to that epic
- No PM labels → Ask user or create in "imported" epic

### 4. Create Local Structure

For each issue to import:

**If Epic:**
```bash
mkdir -p .claude/epics/{epic_name}
# Create epic.md with Git service content and frontmatter
```

**If Task:**
```bash
# Find next available number (001.md, 002.md, etc.)
# Create task file with Git service content
```

Set frontmatter:
```yaml
name: {issue_title}
status: {open|closed based on Git service}
created: {Git service createdAt}
updated: {Git service updatedAt}
gitsrv: {git_service_issue_url}
imported: true
```

### 5. Output

```
📥 Import Complete

Imported:
  Epics: {count}
  Tasks: {count}
  
Created structure:
  {epic_1}/
    - {count} tasks
  {epic_2}/
    - {count} tasks
    
Skipped (already tracked): {count}

Next steps:
  Run /pm:status to see imported work
  Run /pm:sync to ensure full synchronization
```

## Important Notes

Preserve all Git service metadata in frontmatter.
Mark imported files with `imported: true` flag.
Don't overwrite existing local files.
