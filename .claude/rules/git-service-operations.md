# Git Service Operations Guide

为 AI agent 提供的多 Git 服务操作指导文档。

## 概述

本项目支持三种 Git 服务：GitHub、GitLab 和 Gitea。所有 Git 操作都通过统一的函数接口进行，无需关心底层实现差异。

## 使用方法

### 1. 初始化 Git 服务检测

在任何需要 Git 操作的命令开头，都必须先加载函数库并检测当前 Git 服务：

```bash
verify_cli_tool "$GIT_CLI_TOOL" || exit 1

echo "Using $GIT_SERVICE with $GIT_CLI_TOOL CLI"

# 检查仓库保护（防止操作模板仓库）
check_repository_protection
```

### 2. 环境变量

检测完成后，以下环境变量将被设置：
- `$GIT_SERVICE`: 当前使用的 Git 服务 (github/gitlab/gitea)
- `$GIT_CLI_TOOL`: 对应的 CLI 工具 (gh/glab/tea)

### 3. 统一操作接口

使用以下统一函数进行 Git 操作，无需关心具体的 CLI 工具差异：

#### Issue 操作
- `git_create_issue "title" "body_file" "labels"` - 创建 issue
- `git_view_issue "issue_number"` - 查看 issue
- `git_edit_issue "issue_number" "title" "body_file" "add_labels" "assignee"` - 编辑 issue
- `git_add_comment "issue_number" "comment_file"` - 添加评论
- `git_close_issue "issue_number" "comment"` - 关闭 issue
- `git_reopen_issue "issue_number" "comment"` - 重新打开 issue

#### 辅助函数
- `git_get_repo_info` - 获取仓库信息
- `git_get_issue_url "issue_number"` - 生成 issue URL
- `git_create_sub_issue "parent_number" "title" "body_file" "labels"` - 创建子 issue（仅 GitHub）
- `git_list_issues "label_filter" "state"` - 列出 issues

## Git 服务特性差异

### GitHub
- CLI 工具: `gh`
- 支持子 issue（需要 gh-sub-issue 扩展）
- 标签格式: `--label "label1,label2"`
- 完整功能支持

### GitLab
- CLI 工具: `glab`
- 不支持子 issue，会回退到普通 issue
- 标签格式: `--label "label1" --label "label2"`
- 使用 Merge Request 而非 Pull Request
- 支持自建实例

### Gitea
- CLI 工具: `tea`
- 不支持子 issue，会回退到普通 issue
- 标签格式: `--labels "label1,label2"`
- 需要手动配置服务器 URL 和 token
- 完全自建服务

## 错误处理指导

### 1. CLI 工具不可用
如果 CLI 工具不可用，`verify_cli_tool` 函数会：
- 显示错误信息
- 提供安装指导
- 返回非零退出码

处理方式：
```bash
if ! verify_cli_tool "$GIT_CLI_TOOL"; then
  echo "请安装 $GIT_CLI_TOOL CLI 工具后重试"
  exit 1
fi
```

### 2. 仓库保护
`check_repository_protection` 函数会检查是否为 CCPM 模板仓库，如果是则：
- 显示详细错误信息
- 提供修复指导
- 自动退出

### 3. 认证问题
如果 Git 操作失败，通常是认证问题：
- GitHub: `gh auth login`
- GitLab: `glab auth login`
- Gitea: `tea login add`

## 最佳实践

### 1. 文件处理
- 使用临时文件存储 issue 内容：`/tmp/issue-body.md`
- 使用 frontmatter 剥离：`sed '1,/^---$/d; 1,/^---$/d'`
- 确保文件路径正确

### 2. URL 生成
- 使用 `git_get_issue_url` 生成正确的 issue URL
- 不要硬编码 GitHub URL
- 支持自建服务的 URL 格式

### 3. 标签处理
- 使用统一的标签格式：`"label1,label2"`
- 函数会自动转换为对应 CLI 工具的格式
- 常用标签：`epic`, `task`, `bug`, `feature`

### 4. 子 issue 处理
- 优先使用 `git_create_sub_issue`
- 如果不支持子 issue，会自动回退到普通 issue
- GitHub 需要安装 gh-sub-issue 扩展

## 配置文件

配置文件位置：`.claude/config/git-service.json`

格式：
```json
{
  "service": "github|gitlab|gitea",
  "cli_tool": "gh|glab|tea",
  "initialized": true|false,
  "last_updated": "2024-01-15T10:30:00Z"
}
```

配置优先级：
1. 配置文件（如果已初始化）
2. remote URL 自动推断
3. 默认为 GitHub

## 命令模板

在命令文件中使用以下模板：

```bash
#!/bin/bash
verify_cli_tool "$GIT_CLI_TOOL" || exit 1

echo "Using $GIT_SERVICE with $GIT_CLI_TOOL CLI"

# 检查仓库保护
check_repository_protection

# 执行具体操作
issue_number=$(git_create_issue "Issue Title" "/tmp/body.md" "epic,feature")
echo "Created issue #$issue_number"

# 生成 URL
issue_url=$(git_get_issue_url "$issue_number")
echo "Issue URL: $issue_url"
```

## 注意事项

1. **始终先检测服务**：每个命令都必须先调用 `detect_git_service`
2. **使用统一接口**：不要直接调用 `gh`、`glab` 或 `tea` 命令
3. **处理错误**：检查函数返回值，提供有意义的错误信息
4. **保持一致性**：使用相同的标签和命名约定
5. **测试兼容性**：确保在所有支持的 Git 服务上都能正常工作

这个指导文档帮助 AI agent 正确使用多 Git 服务功能，确保操作的一致性和可靠性。
