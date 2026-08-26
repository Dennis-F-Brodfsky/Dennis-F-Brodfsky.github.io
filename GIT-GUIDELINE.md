# Git 开发与提交规范

本规范适用于在本仓库工作的所有 Agent。开始前先阅读 `AGENTS.md`；仅在用户明确要求时提交或推送。已有修改和未跟踪文件均视为用户资产，不得擅自覆盖、删除或纳入提交。

## 分支规范

`main` 始终保持可构建、可部署。除简单文档或用户明确指定外，从最新 `main` 创建短生命周期分支：

```bash
git fetch origin main
git switch -c fix/liquid-tag-condition origin/main
```

分支名使用小写 kebab-case，格式为 `<type>/<short-description>`：

- `feature/add-archive-page`
- `fix/mobile-navigation`
- `docs/update-deployment-guide`
- `refactor/sidebar-template`
- `chore/refresh-assets`

禁止使用个人姓名、无意义编号或 `test`、`temp` 等模糊名称。有 Issue 时可写成 `fix/123-mobile-navigation`。

## Commit 信息规范

采用 Conventional Commits 风格：

```text
<type>(<scope>): <imperative summary>

[optional body]

[optional footer]
```

允许的 `type`：`feat`、`fix`、`docs`、`style`、`refactor`、`test`、`build`、`ci`、`chore`、`revert`。`scope` 可使用 `config`、`layout`、`posts`、`assets`、`pwa` 等，非必要可省略。

```text
fix(layout): correct featured tag condition
docs: add repository Git workflow
feat(posts): add archive page
```

标题使用英文祈使语气，不加句号，建议不超过 72 个字符。正文解释“为什么”和重要取舍，不重复代码差异。关联问题使用 `Refs #123`；确认关闭时使用 `Closes #123`。破坏性变更添加 `BREAKING CHANGE:` footer。一个提交只包含一个逻辑目标，不混入格式化或无关文件。

## 暂存与验证

提交前检查并显式暂存目标文件，禁止无审查地使用 `git add .` 或 `git add -A`：

```bash
git status --short --branch
git diff --check
git diff -- path/to/file
git add path/to/file
git diff --cached --check
git diff --cached
```

涉及站点、配置或模板时必须运行 `jekyll build`，且不得忽略警告。布局或样式变更还应通过 `jekyll serve` 检查页面、链接和响应式显示。验证失败时不得提交为“完成”。

## 同步、合并与冲突

开始工作和推送前运行 `git fetch origin main`。尚未共享的功能分支应通过以下方式更新，保持线性历史：

```bash
git rebase origin/main
```

解决冲突时逐个审查文件，保留双方有效意图；不得使用 `--ours` 或 `--theirs` 批量覆盖。解决后重新运行完整验证，再执行 `git rebase --continue`。不确定远程改动含义时停止并询问用户。

功能分支通过 Pull Request 合入 `main`，默认使用 **Squash and merge**，最终提交信息遵循上述规范。需要保留一组有意义的独立提交时可使用 **Rebase and merge**。避免普通 merge commit；不得将未经审查或构建失败的分支合入 `main`。合并后删除已完成的远程和本地功能分支。

## Pull Request 规范

PR 应包含变更目的、主要实现、验证命令及结果、相关 Issue。视觉或响应式改动需附前后截图；配置或行为变更需说明部署影响和回滚方式。保持 PR 小而聚焦，评审意见处理完毕且 CI 通过后才能合并。

## 推送与安全限制

本仓库使用 SSH remote：

```text
git@github.com:Dennis-F-Brodfsky/Dennis-F-Brodfsky.github.io.git
```

正常推送使用 `git push -u origin <branch>`。禁止对 `main` 使用 `--force` 或 `--force-with-lease`，禁止未经授权执行 `git reset --hard`、`git clean -fd`、rebase 已共享提交或 amend 他人提交。不得把 token、私钥或环境密钥写入 URL、配置、提交信息和日志。

操作完成后运行 `git status --short --branch`，并向用户报告分支、提交哈希、验证结果及推送状态。
