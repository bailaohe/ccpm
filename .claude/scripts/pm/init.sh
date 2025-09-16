#!/bin/bash

echo "Initializing..."
echo ""
echo ""

echo " ██████╗ ██████╗██████╗ ███╗   ███╗"
echo "██╔════╝██╔════╝██╔══██╗████╗ ████║"
echo "██║     ██║     ██████╔╝██╔████╔██║"
echo "╚██████╗╚██████╗██║     ██║ ╚═╝ ██║"
echo " ╚═════╝ ╚═════╝╚═╝     ╚═╝     ╚═╝"

echo "┌─────────────────────────────────┐"
echo "│ Claude Code Project Management  │"
echo "│ by https://x.com/aroussi        │"
echo "└─────────────────────────────────┘"
echo "https://github.com/automazeio/ccpm"
echo ""
echo ""

echo "🚀 Initializing Claude Code PM System"
echo "======================================"
echo ""

# Choose Git service
echo "🔧 Select your Git service:"
echo "  1) GitHub"
echo "  2) GitLab"
echo "  3) Gitea"
echo ""
read -p "Enter your choice (1, 2, or 3): " git_service

case $git_service in
  1)
    echo "✅ Selected GitHub"
    use_github=true
    use_gitlab=false
    use_gitea=false
    ;;
  2)
    echo "✅ Selected GitLab"
    use_github=false
    use_gitlab=true
    use_gitea=false
    ;;
  3)
    echo "✅ Selected Gitea"
    use_github=false
    use_gitlab=false
    use_gitea=true
    ;;
  *)
    echo "❌ Invalid choice, defaulting to GitHub"
    use_github=true
    use_gitlab=false
    use_gitea=false
    ;;
esac

echo ""

# Check for required tools
echo "🔍 Checking dependencies..."

if $use_github; then
  # Check gh CLI
  if command -v gh &> /dev/null; then
    echo "  ✅ GitHub CLI (gh) installed"
  else
    echo "  ❌ GitHub CLI (gh) not found"
    echo ""
    echo "  Installing gh..."
    if command -v brew &> /dev/null; then
      brew install gh
    elif command -v apt-get &> /dev/null; then
      sudo apt-get update && sudo apt-get install gh
    else
      echo "  Please install GitHub CLI manually: https://cli.github.com/"
      exit 1
    fi
  fi

  # Check gh auth status
  echo ""
  echo "🔐 Checking GitHub authentication..."
  if gh auth status &> /dev/null; then
    echo "  ✅ GitHub authenticated"
  else
    echo "  ⚠️ GitHub not authenticated"
    echo "  Running: gh auth login"
    gh auth login
  fi

  # Check for gh-sub-issue extension
  echo ""
  echo "📦 Checking gh extensions..."
  if gh extension list | grep -q "yahsan2/gh-sub-issue"; then
    echo "  ✅ gh-sub-issue extension installed"
  else
    echo "  📥 Installing gh-sub-issue extension..."
    gh extension install yahsan2/gh-sub-issue
  fi

elif $use_gitlab; then
  # Check glab CLI
  if command -v glab &> /dev/null; then
    echo "  ✅ GitLab CLI (glab) installed"
  else
    echo "  ❌ GitLab CLI (glab) not found"
    echo ""
    echo "  Installing glab..."
    if command -v brew &> /dev/null; then
      brew install glab
    elif command -v apt-get &> /dev/null; then
      sudo apt-get update && sudo apt-get install glab
    else
      echo "  Please install GitLab CLI manually: https://gitlab.com/gitlab-org/cli"
      exit 1
    fi
  fi

  # Check glab auth status
  echo ""
  echo "🔐 Checking GitLab authentication..."
  if glab auth status &> /dev/null; then
    echo "  ✅ GitLab authenticated"
  else
    echo "  ⚠️ GitLab not authenticated"
    echo "  Running: glab auth login"
    glab auth login
  fi

elif $use_gitea; then
  # Check tea CLI
  if command -v tea &> /dev/null; then
    echo "  ✅ Gitea CLI (tea) installed"
  else
    echo "  ❌ Gitea CLI (tea) not found"
    echo ""
    echo "  Installing tea..."
    if command -v brew &> /dev/null; then
      brew install tea
    elif command -v apt-get &> /dev/null; then
      # Download and install tea
      echo "  Downloading tea CLI..."
      wget -O /tmp/tea https://dl.gitea.io/tea/0.9.2/tea-0.9.2-linux-amd64
      chmod +x /tmp/tea
      sudo mv /tmp/tea /usr/local/bin/tea
    else
      echo "  Please install Gitea CLI manually: https://gitea.com/gitea/tea"
      exit 1
    fi
  fi

  # Check tea auth status
  echo ""
  echo "🔐 Checking Gitea authentication..."
  if tea login list &> /dev/null && [ "$(tea login list | wc -l)" -gt 1 ]; then
    echo "  ✅ Gitea authenticated"
  else
    echo "  ⚠️ Gitea not authenticated"
    echo "  Please configure Gitea login:"
    read -p "  Gitea server URL: " gitea_url
    read -p "  Username: " gitea_user
    read -s -p "  Access token: " gitea_token
    echo ""
    tea login add --name default --url "$gitea_url" --token "$gitea_token"
  fi
fi

# Create directory structure
echo ""
echo "📁 Creating directory structure..."
mkdir -p .claude/prds
mkdir -p .claude/epics
mkdir -p .claude/rules
mkdir -p .claude/agents
mkdir -p .claude/scripts/pm
echo "  ✅ Directories created"

# Copy scripts if in main repo
if [ -d "scripts/pm" ] && [ ! "$(pwd)" = *"/.claude"* ]; then
  echo ""
  echo "📝 Copying PM scripts..."
  cp -r scripts/pm/* .claude/scripts/pm/
  chmod +x .claude/scripts/pm/*.sh
  echo "  ✅ Scripts copied and made executable"
fi

# Check for git
echo ""
echo "🔗 Checking Git configuration..."
if git rev-parse --git-dir > /dev/null 2>&1; then
  echo "  ✅ Git repository detected"

  # Check remote
  if git remote -v | grep -q origin; then
    remote_url=$(git remote get-url origin)
    echo "  ✅ Remote configured: $remote_url"
    
    # Check if remote is the CCPM template repository
    if [[ "$remote_url" == *"automazeio/ccpm"* ]] || [[ "$remote_url" == *"automazeio/ccpm.git"* ]]; then
      echo ""
      echo "  ⚠️ WARNING: Your remote origin points to the CCPM template repository!"
      echo "  This means any issues you create will go to the template repo, not your project."
      echo ""
      echo "  To fix this:"
      if $use_github; then
        echo "  1. Fork the repository or create your own on GitHub"
        echo "  2. Update your remote:"
        echo "     git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
      elif $use_gitlab; then
        echo "  1. Fork the repository or create your own on GitLab"
        echo "  2. Update your remote:"
        echo "     git remote set-url origin https://gitlab.com/YOUR_USERNAME/YOUR_REPO.git"
      elif $use_gitea; then
        echo "  1. Fork the repository or create your own on Gitea"
        echo "  2. Update your remote:"
        echo "     git remote set-url origin https://your-gitea-server/YOUR_USERNAME/YOUR_REPO.git"
      fi
      echo ""
    fi
  else
    echo "  ⚠️ No remote configured"
    echo "  Add with: git remote add origin <url>"
  fi
else
  echo "  ⚠️ Not a git repository"
  echo "  Initialize with: git init"
fi

# Create CLAUDE.md if it doesn't exist
if [ ! -f "CLAUDE.md" ]; then
  echo ""
  echo "📄 Creating CLAUDE.md..."
  cat > CLAUDE.md << 'EOF'
# CLAUDE.md

> Think carefully and implement the most concise solution that changes as little code as possible.

## Project-Specific Instructions

Add your project-specific instructions here.

## Testing

Always run tests before committing:
- `npm test` or equivalent for your stack

## Code Style

Follow existing patterns in the codebase.
EOF
  echo "  ✅ CLAUDE.md created"
fi

# Create configuration file
echo ""
echo "💾 Saving configuration..."
mkdir -p .claude/config

# Determine service and CLI tool
if $use_github; then
  service="github"
  cli_tool="gh"
elif $use_gitlab; then
  service="gitlab"
  cli_tool="glab"
elif $use_gitea; then
  service="gitea"
  cli_tool="tea"
fi

# Write configuration
current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cat > .claude/config/git-service.json << EOF
{
  "service": "$service",
  "cli_tool": "$cli_tool",
  "initialized": true,
  "last_updated": "$current_date"
}
EOF

echo "  ✅ Configuration saved to .claude/config/git-service.json"

# Summary
echo ""
echo "✅ Initialization Complete!"
echo "=========================="
echo ""
echo "📊 System Status:"
echo "  Git Service: $service"
echo "  CLI Tool: $cli_tool"
if $use_github; then
  gh --version | head -1
  echo "  Extensions: $(gh extension list | wc -l) installed"
  echo "  Auth: $(gh auth status 2>&1 | grep -o 'Logged in to [^ ]*' || echo 'Not authenticated')"
elif $use_gitlab; then
  glab --version | head -1
  echo "  Auth: $(glab auth status 2>&1 | grep -o 'Logged in to [^ ]*' || echo 'Not authenticated')"
elif $use_gitea; then
  tea --version | head -1
  echo "  Logins: $(tea login list | tail -n +2 | wc -l) configured"
fi
echo ""
echo "🎯 Next Steps:"
echo "  1. Create your first PRD: /pm:prd-new <feature-name>"
echo "  2. View help: /pm:help"
echo "  3. Check status: /pm:status"
echo ""
echo "📚 Documentation: README.md"

exit 0
