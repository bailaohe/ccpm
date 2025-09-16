#!/bin/bash

echo "🧪 Testing Multi-Git Service Support"
echo "===================================="
echo ""

# Test Git service detection
echo "📋 Testing Git Service Detection..."

# Load the Git service functions
source .claude/scripts/git/git-service-functions.sh 2>/dev/null || {
  echo "❌ Failed to load git-service-functions.sh"
  exit 1
}

# Test 1: Configuration file detection
echo ""
echo "Test 1: Configuration File Detection"
echo "------------------------------------"

if [ -f ".claude/config/git-service.json" ]; then
  echo "✅ Configuration file exists"
  
  # Test reading configuration
  detect_git_service
  
  if [ -n "$GIT_SERVICE" ] && [ -n "$GIT_CLI_TOOL" ]; then
    echo "✅ Successfully detected: $GIT_SERVICE using $GIT_CLI_TOOL"
  else
    echo "❌ Failed to detect Git service from configuration"
  fi
else
  echo "⚠️ No configuration file found - will test remote URL detection"
  
  # Test remote URL detection
  remote_url=$(git remote get-url origin 2>/dev/null || echo "")
  if [ -n "$remote_url" ]; then
    echo "Remote URL: $remote_url"
    detect_git_service
    echo "Detected: $GIT_SERVICE using $GIT_CLI_TOOL"
  else
    echo "❌ No remote URL found"
  fi
fi

# Test 2: CLI tool verification
echo ""
echo "Test 2: CLI Tool Verification"
echo "-----------------------------"

if verify_cli_tool "$GIT_CLI_TOOL"; then
  echo "✅ CLI tool $GIT_CLI_TOOL is available"
else
  echo "❌ CLI tool $GIT_CLI_TOOL is not available"
  echo "Install instructions provided above"
fi

# Test 3: Repository protection check
echo ""
echo "Test 3: Repository Protection Check"
echo "----------------------------------"

remote_url=$(git remote get-url origin 2>/dev/null || echo "")
if [[ "$remote_url" == *"automazeio/ccpm"* ]]; then
  echo "⚠️ This is the CCPM template repository"
  echo "Repository protection check would prevent operations"
else
  echo "✅ Repository protection check passed"
fi

# Test 4: Unified operations interface
echo ""
echo "Test 4: Unified Operations Interface"
echo "-----------------------------------"

echo "Testing function availability:"

# Check if functions are defined
if declare -f git_create_issue > /dev/null; then
  echo "✅ git_create_issue function available"
else
  echo "❌ git_create_issue function not found"
fi

if declare -f git_view_issue > /dev/null; then
  echo "✅ git_view_issue function available"
else
  echo "❌ git_view_issue function not found"
fi

if declare -f git_add_comment > /dev/null; then
  echo "✅ git_add_comment function available"
else
  echo "❌ git_add_comment function not found"
fi

if declare -f git_close_issue > /dev/null; then
  echo "✅ git_close_issue function available"
else
  echo "❌ git_close_issue function not found"
fi

if declare -f git_get_issue_url > /dev/null; then
  echo "✅ git_get_issue_url function available"
else
  echo "❌ git_get_issue_url function not found"
fi

# Test 5: URL generation
echo ""
echo "Test 5: URL Generation"
echo "---------------------"

if [ -n "$GIT_SERVICE" ]; then
  test_issue_url=$(git_get_issue_url "123")
  echo "Sample issue URL for #123: $test_issue_url"
  
  # Validate URL format
  case "$GIT_SERVICE" in
    "github")
      if [[ "$test_issue_url" == *"github.com"* ]] && [[ "$test_issue_url" == *"/issues/123" ]]; then
        echo "✅ GitHub URL format correct"
      else
        echo "❌ GitHub URL format incorrect"
      fi
      ;;
    "gitlab")
      if [[ "$test_issue_url" == *"gitlab"* ]] && [[ "$test_issue_url" == *"/-/issues/123" ]]; then
        echo "✅ GitLab URL format correct"
      else
        echo "❌ GitLab URL format incorrect"
      fi
      ;;
    "gitea")
      if [[ "$test_issue_url" == *"/issues/123" ]]; then
        echo "✅ Gitea URL format correct"
      else
        echo "❌ Gitea URL format incorrect"
      fi
      ;;
  esac
else
  echo "❌ No Git service detected for URL testing"
fi

# Test 6: Command file compatibility
echo ""
echo "Test 6: Command File Compatibility"
echo "---------------------------------"

modified_commands=(
  "epic-sync.md"
  "issue-sync.md" 
  "issue-start.md"
  "issue-close.md"
)

for cmd in "${modified_commands[@]}"; do
  if [ -f ".claude/commands/pm/$cmd" ]; then
    if grep -q "git-service-functions.sh" ".claude/commands/pm/$cmd"; then
      echo "✅ $cmd: Updated with Git service functions"
    else
      echo "❌ $cmd: Missing Git service functions"
    fi
    
    if grep -q "git-service-operations.md" ".claude/commands/pm/$cmd"; then
      echo "✅ $cmd: References Git service operations guide"
    else
      echo "⚠️ $cmd: Missing reference to operations guide"
    fi
  else
    echo "❌ $cmd: File not found"
  fi
done

# Summary
echo ""
echo "📊 Test Summary"
echo "==============="

echo "Git Service: ${GIT_SERVICE:-'Not detected'}"
echo "CLI Tool: ${GIT_CLI_TOOL:-'Not detected'}"
echo "Configuration: $([ -f '.claude/config/git-service.json' ] && echo 'Present' || echo 'Missing')"
echo "CLI Available: $(verify_cli_tool "$GIT_CLI_TOOL" 2>/dev/null && echo 'Yes' || echo 'No')"

echo ""
echo "🎯 Next Steps:"
echo "1. Ensure your Git service CLI tool is installed and authenticated"
echo "2. Run /pm:init to configure your Git service if not already done"
echo "3. Test creating a simple issue with /pm:epic-sync"
echo ""

exit 0
