#!/bin/bash

# Git Service Functions
# 统一的 Git 服务操作函数库

# 检测并设置 Git 服务配置
detect_git_service() {
  local config_file=".claude/config/git-service.json"
  
  # 如果配置文件存在且已初始化，直接读取
  if [ -f "$config_file" ]; then
    local initialized=$(grep '"initialized"' "$config_file" | grep -o 'true\|false')
    if [ "$initialized" = "true" ]; then
      GIT_SERVICE=$(grep '"service"' "$config_file" | sed 's/.*": *"\([^"]*\)".*/\1/')
      GIT_CLI_TOOL=$(grep '"cli_tool"' "$config_file" | sed 's/.*": *"\([^"]*\)".*/\1/')
      return 0
    fi
  fi
  
  # 如果未初始化，从 remote URL 推断
  local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
  
  if [[ "$remote_url" == *"github.com"* ]]; then
    GIT_SERVICE="github"
    GIT_CLI_TOOL="gh"
  elif [[ "$remote_url" == *"gitlab.com"* ]] || [[ "$remote_url" == *"gitlab"* ]]; then
    GIT_SERVICE="gitlab"
    GIT_CLI_TOOL="glab"
  else
    # 默认假设是 Gitea 或其他自建服务
    GIT_SERVICE="gitea"
    GIT_CLI_TOOL="tea"
  fi
  
  # 更新配置文件
  update_git_service_config "$GIT_SERVICE" "$GIT_CLI_TOOL"
}

# 更新配置文件
update_git_service_config() {
  local service="$1"
  local cli_tool="$2"
  local config_file=".claude/config/git-service.json"
  local current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  mkdir -p "$(dirname "$config_file")"
  
  cat > "$config_file" << EOF
{
  "service": "$service",
  "cli_tool": "$cli_tool",
  "initialized": true,
  "last_updated": "$current_date"
}
EOF
}

# 验证 CLI 工具是否可用
verify_cli_tool() {
  local cli_tool="$1"
  
  if ! command -v "$cli_tool" &> /dev/null; then
    echo "❌ $cli_tool CLI not found. Please install it first."
    case "$cli_tool" in
      "gh")
        echo "Install: brew install gh (macOS) or https://cli.github.com/"
        ;;
      "glab")
        echo "Install: brew install glab (macOS) or https://gitlab.com/gitlab-org/cli"
        ;;
      "tea")
        echo "Install: brew install tea (macOS) or https://gitea.com/gitea/tea"
        ;;
    esac
    return 1
  fi
  
  return 0
}

# 仓库保护检查
check_repository_protection() {
  local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
  if [[ "$remote_url" == *"automazeio/ccpm"* ]] || [[ "$remote_url" == *"automazeio/ccpm.git"* ]]; then
    echo "❌ ERROR: You're trying to sync with the CCPM template repository!"
    echo ""
    echo "This repository (automazeio/ccpm) is a template for others to use."
    echo "You should NOT create issues or PRs here."
    echo ""
    echo "To fix this:"
    case "$GIT_SERVICE" in
      "github")
        echo "1. Fork this repository to your own GitHub account"
        echo "2. Update your remote origin:"
        echo "   git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
        ;;
      "gitlab")
        echo "1. Fork this repository to your own GitLab account"
        echo "2. Update your remote origin:"
        echo "   git remote set-url origin https://gitlab.com/YOUR_USERNAME/YOUR_REPO.git"
        ;;
      "gitea")
        echo "1. Fork this repository to your own Gitea instance"
        echo "2. Update your remote origin:"
        echo "   git remote set-url origin https://your-gitea-server/YOUR_USERNAME/YOUR_REPO.git"
        ;;
    esac
    echo ""
    echo "Current remote: $remote_url"
    exit 1
  fi
}

# 创建 Issue
git_create_issue() {
  local title="$1"
  local body_file="$2"
  local labels="$3"
  
  check_repository_protection
  
  case "$GIT_SERVICE" in
    "github")
      gh issue create --title "$title" --body-file "$body_file" --label "$labels" --json number -q .number
      ;;
    "gitlab")
      # GitLab 使用多个 --label 参数
      local label_args=""
      IFS=',' read -ra LABEL_ARRAY <<< "$labels"
      for label in "${LABEL_ARRAY[@]}"; do
        label_args="$label_args --label $(echo $label | xargs)"
      done
      glab issue create --title "$title" --description-file "$body_file" $label_args --output json | jq -r '.iid'
      ;;
    "gitea")
      tea issue create --title "$title" --body-file "$body_file" --labels "$labels" --output json | jq -r '.number'
      ;;
  esac
}

# 查看 Issue
git_view_issue() {
  local issue_number="$1"
  
  case "$GIT_SERVICE" in
    "github")
      gh issue view "$issue_number" --json state,title,labels,body
      ;;
    "gitlab")
      glab issue view "$issue_number" --output json
      ;;
    "gitea")
      tea issue view "$issue_number" --output json
      ;;
  esac
}

# 编辑 Issue
git_edit_issue() {
  local issue_number="$1"
  local title="$2"
  local body_file="$3"
  local add_labels="$4"
  local assignee="$5"
  
  check_repository_protection
  
  case "$GIT_SERVICE" in
    "github")
      local args=""
      [ -n "$title" ] && args="$args --title \"$title\""
      [ -n "$body_file" ] && args="$args --body-file \"$body_file\""
      [ -n "$add_labels" ] && args="$args --add-label \"$add_labels\""
      [ -n "$assignee" ] && args="$args --add-assignee \"$assignee\""
      eval "gh issue edit $issue_number $args"
      ;;
    "gitlab")
      local args=""
      [ -n "$title" ] && args="$args --title \"$title\""
      [ -n "$body_file" ] && args="$args --description-file \"$body_file\""
      if [ -n "$add_labels" ]; then
        IFS=',' read -ra LABEL_ARRAY <<< "$add_labels"
        for label in "${LABEL_ARRAY[@]}"; do
          args="$args --add-label $(echo $label | xargs)"
        done
      fi
      [ -n "$assignee" ] && args="$args --assignee \"$assignee\""
      eval "glab issue update $issue_number $args"
      ;;
    "gitea")
      local args=""
      [ -n "$title" ] && args="$args --title \"$title\""
      [ -n "$body_file" ] && args="$args --body-file \"$body_file\""
      [ -n "$add_labels" ] && args="$args --add-labels \"$add_labels\""
      [ -n "$assignee" ] && args="$args --add-assignees \"$assignee\""
      eval "tea issue edit $issue_number $args"
      ;;
  esac
}

# 添加评论
git_add_comment() {
  local issue_number="$1"
  local comment_file="$2"
  
  check_repository_protection
  
  case "$GIT_SERVICE" in
    "github")
      gh issue comment "$issue_number" --body-file "$comment_file"
      ;;
    "gitlab")
      glab issue note "$issue_number" --message-file "$comment_file"
      ;;
    "gitea")
      tea comment "$issue_number" --body-file "$comment_file"
      ;;
  esac
}

# 关闭 Issue
git_close_issue() {
  local issue_number="$1"
  local comment="$2"
  
  check_repository_protection
  
  case "$GIT_SERVICE" in
    "github")
      if [ -n "$comment" ]; then
        echo "$comment" | gh issue comment "$issue_number" --body-file -
      fi
      gh issue close "$issue_number"
      ;;
    "gitlab")
      if [ -n "$comment" ]; then
        echo "$comment" | glab issue note "$issue_number" --message-file -
      fi
      glab issue close "$issue_number"
      ;;
    "gitea")
      if [ -n "$comment" ]; then
        echo "$comment" | tea comment "$issue_number" --body-file -
      fi
      tea issue close "$issue_number"
      ;;
  esac
}

# 重新打开 Issue
git_reopen_issue() {
  local issue_number="$1"
  local comment="$2"
  
  check_repository_protection
  
  case "$GIT_SERVICE" in
    "github")
      if [ -n "$comment" ]; then
        echo "$comment" | gh issue comment "$issue_number" --body-file -
      fi
      gh issue reopen "$issue_number"
      ;;
    "gitlab")
      if [ -n "$comment" ]; then
        echo "$comment" | glab issue note "$issue_number" --message-file -
      fi
      glab issue reopen "$issue_number"
      ;;
    "gitea")
      if [ -n "$comment" ]; then
        echo "$comment" | tea comment "$issue_number" --body-file -
      fi
      tea issue reopen "$issue_number"
      ;;
  esac
}

# 获取仓库信息
git_get_repo_info() {
  case "$GIT_SERVICE" in
    "github")
      gh repo view --json nameWithOwner -q .nameWithOwner
      ;;
    "gitlab")
      glab repo view --output json | jq -r '.path_with_namespace'
      ;;
    "gitea")
      # Gitea 需要从 remote URL 解析
      local remote_url=$(git remote get-url origin)
      echo "$remote_url" | sed 's|.*[:/]\([^/]*/[^/]*\)\.git.*|\1|'
      ;;
  esac
}

# 生成 Issue URL
git_get_issue_url() {
  local issue_number="$1"
  local repo_info=$(git_get_repo_info)
  
  case "$GIT_SERVICE" in
    "github")
      echo "https://github.com/$repo_info/issues/$issue_number"
      ;;
    "gitlab")
      echo "https://gitlab.com/$repo_info/-/issues/$issue_number"
      ;;
    "gitea")
      local remote_url=$(git remote get-url origin)
      local base_url=$(echo "$remote_url" | sed 's|^\(https\?://[^/]*\).*|\1|')
      echo "$base_url/$repo_info/issues/$issue_number"
      ;;
  esac
}

# 创建子 Issue
git_create_sub_issue() {
  local parent_number="$1"
  local title="$2"
  local body_file="$3"
  local labels="$4"
  
  check_repository_protection
  
  case "$GIT_SERVICE" in
    "github")
      # 检查是否有 gh-sub-issue 扩展
      if gh extension list | grep -q "yahsan2/gh-sub-issue"; then
        gh sub-issue create --parent "$parent_number" --title "$title" --body-file "$body_file" --label "$labels" --json number -q .number
      else
        # 回退到普通 issue
        git_create_issue "$title" "$body_file" "$labels"
      fi
      ;;
    "gitlab"|"gitea")
      # GitLab 和 Gitea 不支持子 issue，创建普通 issue
      git_create_issue "$title" "$body_file" "$labels"
      ;;
  esac
}

# 列出 Issues
git_list_issues() {
  local label_filter="$1"
  local state="$2"  # open, closed, all
  
  case "$GIT_SERVICE" in
    "github")
      local args="--limit 1000 --json number,title,body,state,labels,createdAt,updatedAt"
      [ -n "$label_filter" ] && args="--label \"$label_filter\" $args"
      [ -n "$state" ] && args="--state \"$state\" $args"
      eval "gh issue list $args"
      ;;
    "gitlab")
      local args="--output json"
      [ -n "$label_filter" ] && args="--label \"$label_filter\" $args"
      [ -n "$state" ] && args="--state \"$state\" $args"
      eval "glab issue list $args"
      ;;
    "gitea")
      local args="--output json"
      [ -n "$label_filter" ] && args="--labels \"$label_filter\" $args"
      [ -n "$state" ] && args="--state \"$state\" $args"
      eval "tea issue list $args"
      ;;
  esac
}
