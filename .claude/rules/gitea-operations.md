# Gitea Operations Rule

Standard patterns for Gitea CLI operations across all commands using tea.

## CRITICAL: Repository Protection

**Before ANY Gitea operation that creates/modifies issues or PRs:**

```bash
# Check if remote origin is the CCPM template repository
remote_url=$(git remote get-url origin 2>/dev/null || echo "")
if [[ "$remote_url" == *"automazeio/ccpm"* ]] || [[ "$remote_url" == *"automazeio/ccpm.git"* ]]; then
  echo "❌ ERROR: You're trying to sync with the CCPM template repository!"
  echo ""
  echo "This repository (automazeio/ccpm) is a template for others to use."
  echo "You should NOT create issues or PRs here."
  echo ""
  echo "To fix this:"
  echo "1. Fork this repository to your own Gitea account"
  echo "2. Update your remote origin:"
  echo "   git remote set-url origin https://your-gitea-instance.com/YOUR_USERNAME/YOUR_REPO.git"
  echo ""
  echo "Or if this is a new project:"
  echo "1. Create a new repository on your Gitea instance"
  echo "2. Update your remote origin:"
  echo "   git remote set-url origin https://your-gitea-instance.com/YOUR_USERNAME/YOUR_REPO.git"
  echo ""
  echo "Current remote: $remote_url"
  exit 1
fi
```

This check MUST be performed in ALL commands that:
- Create issues (`tea issue create`)
- Edit issues (`tea issue edit`)
- Comment on issues (`tea issue comment`)
- Create PRs (`tea pull create`)
- Any other operation that modifies the Gitea repository

## Authentication

**Don't pre-check authentication.** Just run the command and handle failure:

```bash
tea {command} || echo "❌ Tea CLI failed. Run: tea login add"
```

## Login Management

### Initial Setup
```bash
# Add a new Gitea login
tea login add --name {instance-name} --url {gitea-url} --token {access-token}

# List existing logins
tea login list

# Set default login
tea login default {instance-name}
```

## Common Operations

### Get Issue Details
```bash
tea issue view {number} --output json
```

### Create Issue
```bash
# ALWAYS check remote origin first!
tea issue create --title "{title}" --description "{description}" --labels "{labels}"
```

### Update Issue
```bash
# ALWAYS check remote origin first!
tea issue edit {number} --add-labels "{label}" --add-assignees {username}
```

### Add Comment
```bash
# ALWAYS check remote origin first!
tea comment {number} --body "{comment}"
```

### Pull Request Operations
```bash
# Create PR
tea pull create --title "{title}" --description "{description}" --base {base-branch} --head {head-branch}

# List PRs
tea pull list --state {open|closed|all}

# Merge PR
tea pull merge {number} --style {merge|rebase|squash}

# Checkout PR locally
tea pull checkout {number}
```

### Repository Operations
```bash
# List repositories
tea repo list

# Create repository
tea repo create --name {repo-name} --description "{description}"

# Clone repository
tea clone {owner}/{repo}
```

### Release Management
```bash
# List releases
tea release list

# Create release
tea release create --tag {tag} --title "{title}" --note "{description}"

# Delete release
tea release delete {tag} --confirm
```

## Error Handling

If any tea command fails:
1. Show clear error: "❌ Gitea operation failed: {command}"
2. Suggest fix: "Run: tea login add" or check issue/PR number
3. Don't retry automatically

## Important Notes

- **ALWAYS** check remote origin before ANY write operation to Gitea
- Trust that tea CLI is installed and authenticated
- Use --output json for structured output when parsing
- Keep operations atomic - one tea command per action
- Don't check rate limits preemptively
- Tea works best when run from within a git repository directory
- Configuration is stored in `$XDG_CONFIG_HOME/tea` or `~/.config/tea`

## Context Awareness

Tea automatically detects repository context when run from within a git repository:
- No need to specify `--repo` flag when in repository directory
- Automatically uses appropriate login based on remote URL
- Respects upstream/fork workflow patterns

## Output Formats

Tea supports multiple output formats:
- `--output simple` (default)
- `--output table`
- `--output csv`
- `--output tsv`
- `--output yaml`
- `--output json`

Use JSON format for programmatic processing of results.
