---
layout: post
title: "在 WSL2 Ubuntu 中配置 Git 和 GitHub CLI"
date: 2026-09-02 00:00:00 +0800
tags:
  - WSL2
  - Linux
  - Git
  - GitHub CLI
  - 开发环境
---

这次配置 GitHub CLI，登录耗时最长。`gh auth login --web` 没有打开 Windows 浏览器，反倒启动了 WSL 里的 Linux Chrome。浏览器没能正常工作，终端也被错误日志占住。最后我让 `gh` 跳过这次浏览器调用，在 Windows 中手动完成设备授权，登录才走通。

处理这个问题时，我顺手把 Git、SSH 和 GitHub CLI 的配置从头核对了一遍。环境是 WSL2 中的 Ubuntu 20.04，已经装有 Git 2.25.1 和 GitHub CLI 2.98.0，仓库通过 SSH 连接 GitHub。下面的安装命令留给配置新环境时使用，已经执行的检查和处理会在正文中明确写出。

## 先看当前状态

先看版本。

```bash
git --version
gh --version
```

这台环境当时返回的主要版本信息如下。

```text
git version 2.25.1
gh version 2.98.0
```

接着确认 Git 的身份配置是否存在。公开记录里不应直接粘贴真实姓名和邮箱，因此这里只保留查询命令。

```bash
git config --global --get user.name
git config --global --get user.email
git config --global --get credential.helper
```

当前环境的 `user.name` 和 `user.email` 都有值。检查时还发现，`credential.helper` 被设成了 `osxkeychain`，而 WSL 中没有对应程序。这项旧配置没有影响当前的 SSH 远端，却可能让以后的 HTTPS 操作调用一个不存在的凭据助手。确认无用后，我取消了全局设置。

```bash
git config --global --unset credential.helper
```

再次查询时，`credential.helper` 已经没有全局配置。下面的命令还会检查系统、全局和仓库等配置层级，能够找到其他文件里的同名设置。

```bash
git config --show-origin --get-all credential.helper
```

## 新环境中的 Git 基本配置

新装的 Ubuntu 可以通过 APT 安装 Git。下面是供新环境使用的命令，本次检查没有重复运行。

```bash
sudo apt update
sudo apt install git
```

安装后设置提交记录使用的姓名和邮箱。邮箱可以使用 GitHub 提供的隐私邮箱，示例值需要替换。

```bash
git config --global user.name "<your-name>"
git config --global user.email "<your-email>"
git config --global init.defaultBranch main
```

最后一项把新仓库的初始分支设为 `main`。当前环境没有这项全局配置，它不会改变已经存在的仓库，只会影响以后运行 `git init` 创建的新仓库。

可以用下面的命令复查配置来自哪里。输出会带出真实家目录、姓名和邮箱，复制到公开位置以前要先处理。

```bash
git config --global --list --show-origin
```

## 用 SSH 连接 GitHub

当前环境的 `~/.ssh` 中已有私钥、公钥和 `known_hosts`，仓库的 `origin` 也采用 `git@<host>:<owner>/<repo>.git` 这一类地址。这里仅记录协议和地址格式。

新环境先检查现有密钥，别急着生成新的，以免覆盖仍在使用的文件。

```bash
ls -al ~/.ssh
```

没有合适的密钥时，可以生成 Ed25519 密钥，并为私钥设置口令。

```bash
ssh-keygen -t ed25519 -C "<your-email>"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

公钥可以通过 GitHub 网页添加，也可以在 `gh` 登录成功以后交给 GitHub CLI 上传。

```bash
gh ssh-key add ~/.ssh/id_ed25519.pub --title "<device-name>"
```

密钥添加到 GitHub 后，再测试 SSH 认证。

```bash
ssh -T git@github.com
```

第一次连接时，SSH 可能要求确认 GitHub 主机指纹。这里不能只凭提示输入 `yes`，应先与 GitHub 官方公布的指纹核对。当前会话没有重新运行 SSH 测试，所以本文不补写成功输出。

已有本地仓库时，可以这样设置远端地址。占位符都要替换成自己的值。

```bash
git remote add origin git@github.com:<owner>/<repo>.git
git remote -v
```

如果 `origin` 已经存在，应查看现有地址，再按需修改。

```bash
git remote set-url origin git@github.com:<owner>/<repo>.git
```

## 安装 GitHub CLI

当前系统已经配置 GitHub CLI 官方 APT 软件源，`gh` 包也来自该源。GitHub CLI 的 Linux 安装说明会更新密钥和软件源细节，实际安装时应以官方页面的最新命令为准。下面这组命令摘取的是 2026 年 9 月核对到的 Ubuntu 安装流程。

```bash
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
  && sudo mkdir -p -m 755 /etc/apt/keyrings \
  && out=$(mktemp) \
  && wget -nv -O "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  && sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg < "$out" >/dev/null \
  && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null \
  && sudo apt update \
  && sudo apt install gh -y
```

装好以后看一眼版本，确认当前 shell 已经能找到 `gh`。

```bash
gh --version
```

## 登录 GitHub CLI

当前 `gh` 配置选择 SSH 作为 Git 操作协议。第一次登录使用了下面的命令。现有 SSH 密钥已经另外配置，因此跳过了密钥上传提示。

```bash
gh auth login \
  --hostname github.com \
  --git-protocol ssh \
  --web \
  --skip-ssh-key
```

命令会引导用户在浏览器中授权。GitHub CLI 会优先把令牌放进系统凭据存储；找不到可用的凭据存储时，它可能退回到配置文件。不要把令牌作为普通命令参数，也不要把 `~/.config/gh/hosts.yml` 的内容贴进文章、日志或提交记录。

## 绕过 WSL2 中失败的浏览器启动

这次登录在打开网页时卡住了。`gh` 找到的是安装在 WSL 内的 Linux Chrome，于是直接启动它。Chrome 没有正常打开网页，终端随后被进程和错误日志占住，其中的报错指向 D-Bus 或图形会话。继续修这个浏览器偏离了眼前的任务，我只需要完成一次设备授权。

我先按 `Ctrl+C` 结束这次登录，再临时把 `GH_BROWSER` 指向 `/bin/true`。

```bash
GH_BROWSER=/bin/true gh auth login \
  --hostname github.com \
  --git-protocol ssh \
  --web \
  --skip-ssh-key
```

这条命令仍然走 GitHub 的设备授权流程。运行后先记下终端显示的一次性验证码，再按提示继续。`gh` 调用浏览器时，`/bin/true` 会立即返回，WSL 中的 Chrome 也就不会启动。接着在 Windows 浏览器中手动打开设备登录页。

```text
https://github.com/login/device
```

输入终端显示的一次性验证码并授权，再回到 WSL 等待。终端最终显示认证完成，并写入 SSH 作为 Git 操作协议。`GH_BROWSER=/bin/true` 只对这一条命令生效，不会永久修改系统浏览器设置。

如果登录进程迟迟没有退出，可以另开一个 WSL 终端检查状态。`timeout` 能限制这次检查的等待时间。

```bash
timeout 10s gh auth status --hostname github.com
```

后续测试还遇到过一次 `EOF`。当时 WSL 中的 `HTTP_PROXY` 与 `HTTPS_PROXY` 指向 `127.0.0.1` 上的代理端口，认证检查也没有正常完成。结合当时的代理设置，问题更可能出在 WSL 到 Windows 代理的连接上，不能只凭这次输出认定令牌失效。

可以临时取消代理变量，分开检查认证和 API。

```bash
env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
  -u http_proxy -u https_proxy -u all_proxy \
  gh auth status --hostname github.com

env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
  -u http_proxy -u https_proxy -u all_proxy \
  gh repo view
```

如果取消代理后能够访问，就该继续检查 WSL 到 Windows 代理的连接。传统 WSL2 NAT 网络中，WSL 内的 `127.0.0.1` 指向 WSL 自身。Windows 代理通常还要允许局域网连接，并改用 WSL 看到的宿主机地址。本文没有记录后续采用的永久代理配置，因此不补写未经验证的持久化命令。

我后来在平时使用的交互式终端再次检查，命令能够正常返回认证结果。

```bash
gh auth status --hostname github.com
```

这项结果说明 GitHub CLI 的登录配置可用，前面遇到的 `EOF` 与认证失败提示来自当时的网络环境。当前仓库一直使用 SSH，不需要用 `gh auth setup-git` 配置 HTTPS 凭据助手。如果以后改用 HTTPS 远端，可以再执行下面的命令。

```bash
gh auth setup-git --hostname github.com
```

以后遇到令牌失效或权限范围变化，可以刷新当前活动账户的认证。当前认证已经可用，这次没有执行刷新。

```bash
gh auth refresh --hostname github.com
```

## 配置后的检查清单

下面几条命令分别检查 Git 配置、仓库远端、SSH 连接和 GitHub API。本文已经确认 Git 配置、SSH 远端和 `gh auth status`，没有在本次记录中重新运行 `ssh -T`，也没有记录 `gh repo view` 的成功输出。

```bash
git config --global --get user.name
git config --global --get user.email
git remote -v
ssh -T git@github.com
gh auth status --hostname github.com
gh repo view
```

这些命令的输出可能包含姓名、邮箱、账户名与仓库名，公开终端记录以前要逐项检查。对这次配置来说，日常交互式终端已经能够返回 `gh` 认证状态，最初那个打不开的 WSL 浏览器也不再挡住登录。

## 参考资料

- [GitHub CLI 在 Linux 上的安装说明](https://github.com/cli/cli/blob/trunk/docs/install_linux.md)
- [GitHub CLI 登录命令手册](https://cli.github.com/manual/gh_auth_login)
- [GitHub CLI 认证状态命令手册](https://cli.github.com/manual/gh_auth_status)
- [GitHub CLI 刷新认证命令手册](https://cli.github.com/manual/gh_auth_refresh)
- [GitHub CLI 环境变量说明](https://cli.github.com/manual/gh_help_environment)
- [GitHub 的 SSH 密钥生成说明](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
