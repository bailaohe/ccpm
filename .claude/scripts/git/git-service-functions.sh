#!/bin/bash

# Git Service Functions
# 统一的 Git 服务操作函数库

# 检测并设置 Git 服务配置
detect_git_service() {
  # 如果环境变量已设置，直接使用
  if [ -n "$GIT_SERVICE" ] && [ -n "$GIT_CLI_TOOL" ]; then
    return 0
  fi
  
  # 如果环境变量未设置，从 remote URL 推断
  local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
  
  if [[ "$remote_url" == *"github.com"* ]]; then
    export GIT_SERVICE="github"
    export GIT_CLI_TOOL="gh"
  elif [[ "$remote_url" == *"gitlab.com"* ]] || [[ "$remote_url" == *"gitlab"* ]]; then
    export GIT_SERVICE="gitlab"
    export GIT_CLI_TOOL="glab"
  else
    # 默认假设是 Gitea 或其他自建服务
    export GIT_SERVICE="gitea"
    export GIT_CLI_TOOL="tea"
  fi
}

# 更新 settings.local.json 中的环境变量配置和 hooks
update_git_service_config() {
  local service="$1"
  local cli_tool="$2"
  local settings_file=".claude/settings.local.json"
  
  # 如果 settings.local.json 不存在，创建基本结构
  if [ ! -f "$settings_file" ]; then
    cat > "$settings_file" << 'EOF'
{
  "permissions": {
    "allow": []
  }
}
EOF
  fi
  
  # 使用 jq 更新配置，如果没有 jq 则使用 sed 备用方案
  if command -v jq &> /dev/null; then
    # 使用 jq 进行复杂的 JSON 合并操作
    jq --arg service "$service" --arg cli_tool "$cli_tool" '
      # 确保 env 对象存在并更新环境变量
      .env = (.env // {}) |
      .env.GIT_SERVICE = $service |
      .env.GIT_CLI_TOOL = $cli_tool |
      
      # 确保 hooks 对象存在
      .hooks = (.hooks // {}) |
      
      # 确保 PreToolUse 数组存在
      .hooks.PreToolUse = (.hooks.PreToolUse // []) |
      
      # 检查是否已存在 Bash matcher 的 hook
      if (.hooks.PreToolUse | map(select(.matcher == "Bash")) | length) == 0 then
        # 如果不存在，添加新的 Bash hook
        .hooks.PreToolUse += [{
          "matcher": "Bash",
          "hooks": [{
            "type": "command",
            "command": "source .claude/scripts/git/git-service-functions.sh"
          }]
        }]
      else
        # 如果已存在，更新现有的 Bash hook
        .hooks.PreToolUse = (.hooks.PreToolUse | map(
          if .matcher == "Bash" then
            .hooks = [{
              "type": "command", 
              "command": "source .claude/scripts/git/git-service-functions.sh"
            }]
          else
            .
          end
        ))
      end
    ' "$settings_file" > "${settings_file}.tmp" && mv "${settings_file}.tmp" "$settings_file"
  else
    # 备用方案：使用 sed 和 awk 进行更新
    local temp_file="${settings_file}.tmp"
    
    # 首先确保文件有正确的基本结构
    if ! grep -q '"env"' "$settings_file"; then
      # 添加 env 部分
      sed 's/}$/,\n  "env": {}\n}/' "$settings_file" > "$temp_file"
      mv "$temp_file" "$settings_file"
    fi
    
    if ! grep -q '"hooks"' "$settings_file"; then
      # 添加 hooks 部分
      sed 's/}$/,\n  "hooks": {\n    "PreToolUse": []\n  }\n}/' "$settings_file" > "$temp_file"
      mv "$temp_file" "$settings_file"
    fi
    
    # 更新环境变量
    if grep -q '"GIT_SERVICE"' "$settings_file"; then
      sed -i.bak 's/"GIT_SERVICE": *"[^"]*"/"GIT_SERVICE": "'"$service"'"/' "$settings_file"
    else
      sed -i.bak '/"env": *{/ a\
    "GIT_SERVICE": "'"$service"'",' "$settings_file"
    fi
    
    if grep -q '"GIT_CLI_TOOL"' "$settings_file"; then
      sed -i.bak 's/"GIT_CLI_TOOL": *"[^"]*"/"GIT_CLI_TOOL": "'"$cli_tool"'"/' "$settings_file"
    else
      sed -i.bak '/"env": *{/ a\
    "GIT_CLI_TOOL": "'"$cli_tool"'",' "$settings_file"
    fi
    
    # 添加或更新 PreToolUse hooks
    if ! grep -q '"matcher": "Bash"' "$settings_file"; then
      # 添加新的 Bash hook
      sed -i.bak '/"PreToolUse": *\[/ a\
      {\
        "matcher": "Bash",\
        "hooks": [\
          {\
            "type": "command",\
            "command": "source .claude/scripts/git/git-service-functions.sh"\
          }\
        ]\
      },' "$settings_file"
    fi
    
    rm -f "${settings_file}.bak"
  fi
}

# 解析文本内容：如果参数是文件路径且文件存在，则读取文件内容；否则直接返回参数内容
# 
# 使用场景：
# - tea 工具不支持 --body-file 或 --message-file 参数，只能接受直接的文本内容
# - 此函数提供统一的处理方式，支持文件路径和直接文本内容两种输入
# 
# 参数：
#   $1 - 输入内容，可以是文件路径或直接的文本内容
# 
# 返回：
#   如果输入是存在的文件路径，返回文件内容；否则返回输入本身
resolve_text_content() {
  local input="$1"
  
  # 检查输入是否为空
  if [ -z "$input" ]; then
    echo ""
    return 0
  fi
  
  # 检查是否是文件路径且文件存在
  if [ -f "$input" ]; then
    # 是文件且存在，读取文件内容
    cat "$input"
  else
    # 不是文件或文件不存在，直接返回输入内容
    echo "$input"
  fi
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
      local repo_info=$(git_get_repo_info)
      local body_content=$(resolve_text_content "$body_file")
      local output=$(tea issue create --repo "$repo_info" --title "$title" --description "$body_content" --labels "$labels" 2>&1)
      echo "$output" | grep -o '#[0-9]\+' | head -1 | sed 's/#//'
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
      local repo_info=$(git_get_repo_info)
      tea issue view "$issue_number" --repo "$repo_info"
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
      local repo_info=$(git_get_repo_info)
      local args="--repo \"$repo_info\""
      [ -n "$title" ] && args="$args --title \"$title\""
      if [ -n "$body_file" ]; then
        local body_content=$(resolve_text_content "$body_file")
        args="$args --description \"$body_content\""
      fi
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
      local repo_info=$(git_get_repo_info)
      local comment_content=$(resolve_text_content "$comment_file")
      tea comment --repo "$repo_info" "$issue_number" "$comment_content"
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
        local repo_info=$(git_get_repo_info)
        tea comment --repo "$repo_info" "$issue_number" "$comment"
      fi
      tea issue close --repo "$repo_info" "$issue_number"
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
        local repo_info=$(git_get_repo_info)
        tea comment --repo "$repo_info" "$issue_number" "$comment"
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
      local args=""
      [ -n "$label_filter" ] && args="--labels \"$label_filter\" $args"
      [ -n "$state" ] && args="--state \"$state\" $args"
      eval "tea issue list $args"
      ;;
  esac
}
