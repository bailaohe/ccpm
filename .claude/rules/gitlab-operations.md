# GitLab Operations Rule

Standard patterns for GitLab CLI operations across all commands using glab.

## CRITICAL: Repository Protection

**Before ANY GitLab operation that creates/modifies issues or merge requests:**

```bash
# Check if remote origin is the CCPM template repository
remote_url=$(git remote get-url origin 2>/dev/null || echo "")
if [[ "$remote_url" == *"automazeio/ccpm"* ]] || [[ "$remote_url" == *"automazeio/ccpm.git"* ]]; then
  echo "❌ ERROR: You're trying to sync with the CCPM template repository!"
  echo ""
  echo "This repository (automazeio/ccpm) is a template for others to use."
  echo "You should NOT create issues or merge requests here."
  echo ""
  echo "To fix this:"
  echo "1. Fork this repository to your own GitLab account"
  echo "2. Update your remote origin:"
  echo "   git remote set-url origin https://gitlab.com/YOUR_USERNAME/YOUR_REPO.git"
  echo ""
  echo "Or if this is a new project:"
  echo "1. Create a new repository on GitLab"
  echo "2. Update your remote origin:"
  echo "   git remote set-url origin https://gitlab.com/YOUR_USERNAME/YOUR_REPO.git"
  echo ""
  echo "Current remote: $remote_url"
  exit 1
fi
```

This check MUST be performed in ALL commands that:
- Create issues (`glab issue create`)
- Edit issues (`glab issue update`)
- Comment on issues (`glab issue note`)
- Create merge requests (`glab mr create`)
- Any other operation that modifies the GitLab repository

## Authentication

**Don't pre-check authentication.** Just run the command and handle failure:

```bash
glab {command} || echo "❌ GitLab CLI failed. Run: glab auth login"
```

## Authentication Management

### Initial Setup
```bash
# Login to GitLab
glab auth login

# Login to self-hosted GitLab instance
glab auth login --hostname {gitlab-instance.com}

# Check authentication status
glab auth status

# Use token authentication
glab auth login --token {access-token}
```

## Common Operations

### Get Issue Details
```bash
glab issue view {number} --output json
```

### Create Issue
```bash
# ALWAYS check remote origin first!
glab issue create --title "{title}" --description "{description}" --label "{labels}"
```

### Update Issue
```bash
# ALWAYS check remote origin first!
glab issue update {number} --add-label "{label}" --assignee {username}
```

### Add Comment
```bash
# ALWAYS check remote origin first!
glab issue note {number} --message "{comment}"
```

### Merge Request Operations
```bash
# Create MR
glab mr create --title "{title}" --description "{description}" --source-branch {source} --target-branch {target}

# List MRs
glab mr list --state {opened|closed|merged|all}

# Merge MR
glab mr merge {number} --merge-commit

# Approve MR
glab mr approve {number}

# Checkout MR locally
glab mr checkout {number}

# View MR details
glab mr view {number} --output json
```

### Repository Operations
```bash
# List repositories
glab repo list

# Create repository
glab repo create {name} --description "{description}"

# Clone repository
glab repo clone {group/project}

# Fork repository
glab repo fork {group/project}

# View repository details
glab repo view {group/project}
```

### Pipeline Operations
```bash
# List pipelines
glab pipeline list

# View pipeline status
glab pipeline status

# Run pipeline
glab pipeline run

# Cancel pipeline
glab pipeline cancel {pipeline-id}

# Retry pipeline
glab pipeline retry {pipeline-id}
```

### Release Management
```bash
# List releases
glab release list

# Create release
glab release create {tag} --name "{title}" --notes "{description}"

# View release
glab release view {tag}

# Delete release
glab release delete {tag}
```

## Error Handling

If any glab command fails:
1. Show clear error: "❌ GitLab operation failed: {command}"
2. Suggest fix: "Run: glab auth login" or check issue/MR number
3. Don't retry automatically

## Important Notes

- **ALWAYS** check remote origin before ANY write operation to GitLab
- Trust that glab CLI is installed and authenticated
- Use --output json for structured output when parsing
- Keep operations atomic - one glab command per action
- Don't check rate limits preemptively
- Glab works best when run from within a git repository directory
- Configuration is stored in `~/.config/glab-cli`

## Context Awareness

Glab automatically detects repository context when run from within a git repository:
- No need to specify `--repo` flag when in repository directory
- Automatically uses appropriate authentication based on remote URL
- Respects upstream/fork workflow patterns
- Supports both GitLab.com and self-hosted GitLab instances

## Output Formats

Glab supports multiple output formats:
- `--output table` (default for lists)
- `--output json` (for programmatic processing)
- `--output yaml`

Use JSON format for programmatic processing of results.

## GitLab-Specific Features

### Labels and Milestones
```bash
# List labels
glab label list

# Create label
glab label create {name} --color {hex-color}

# List milestones
glab milestone list

# Create milestone
glab milestone create {title} --description "{description}"
```

### Project Management
```bash
# List project members
glab project members

# View project variables
glab variable list

# Set project variable
glab variable set {key} {value}
```

### CI/CD Integration
```bash
# View job logs
glab job logs {job-id}

# Download job artifacts
glab job artifacts {job-id}

# View environment deployments
glab environment list
```

## Best Practices

1. Always use descriptive titles and descriptions for issues and MRs
2. Use labels consistently for better organization
3. Link related issues and MRs using GitLab's cross-referencing syntax
4. Utilize GitLab's built-in CI/CD pipeline integration
5. Take advantage of GitLab's issue boards and milestone tracking
6. Use merge request templates for consistent documentation
