---
layout: post
title: "一次 WSL2 磁盘清理记录"
date: 2026-08-30 00:00:00 +0800
tags:
  - WSL2
  - Linux
  - VHDX
  - 磁盘清理
  - 开发环境
---

2026 年 8 月 15 日，我检查了 WSL2 中 Ubuntu 发行版的磁盘占用。清理前，用户主目录 `~` 大约占了 10 GiB，整个 Linux 文件系统已经使用约 14 GiB。磁盘总容量有 251 GiB，当时并不缺空间。这次检查的目的，是找出多年开发留下的大目录，并清掉已经确定不用的内容。

## 第一次扫描

我先看根文件系统和主目录的总体占用，再找主目录中最大的文件。这几条命令会把隐藏目录算进去。

```bash
df -hT "$HOME"
du -x -h --max-depth=1 "$HOME" 2>/dev/null | sort -h
find "$HOME" -xdev -type f -printf '%s\t%p\n' 2>/dev/null \
  | sort -nr | head -30 \
  | numfmt --field=1 --to=iec-i --suffix=B
```

`du` 和 `find` 中的 `-x`、`-xdev` 都把扫描限制在当前文件系统内。这样可以避开挂载在 `/mnt` 下的 Windows 磁盘，也不会把其他挂载点的文件混入结果。主目录中占用较大的位置如下。

| 目录 | 大小 |
| --- | --- |
| `~/nltk_data` | 3.3 GiB |
| `~/.local` | 2.8 GiB |
| `~/miniconda3` | 1.5 GiB |
| `~/.vscode-server` | 1.2 GiB |
| `~/.nvm` | 537 MiB |
| `~/docker` | 351 MiB |

最大的单个文件位于旧 Python 3.7 环境中。`libtorch_cuda.so` 大约占了 1.2 GiB，另外还有 PyTorch、CUDA、Caffe2 和 OpenCV 等旧包。它们都装在 `~/.local/lib/python3.7` 下。

这次扫描也说明了一件很实际的事。目录大不等于应该直接删除。`~/.local`、`~/.vscode-server` 和 Docker 共享目录都有明确用途，需要先确认里面是什么，再决定清理范围。

## 删除 NLTK 数据

`~/nltk_data` 已经不再使用。删除前，我先确认目标确实是一个目录，再核对它的大小和文件系统剩余空间。

```bash
stat -c 'type=%F path=%n' "$HOME/nltk_data"
du -sh "$HOME/nltk_data"
df -h "$HOME"
```

这一步释放约 3.3 GiB。主目录从约 10 GiB 降到 6.8 GiB。

## 卸载 Miniconda 并检查残留

`~/miniconda3` 大约占 1.5 GiB，其中有 `base` 和 `colab_env` 两个环境。卸载前，我检查了环境列表、shell 初始化配置和 Conda 的用户状态目录。

```bash
du -sh "$HOME/miniconda3"
"$HOME/miniconda3/bin/conda" env list
find "$HOME" -maxdepth 1 \
  \( -name '.conda' -o -name '.condarc' -o -name '.continuum' \) \
  -print
rg -n --hidden 'conda|miniconda|anaconda' \
  "$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.zshrc" \
  2>/dev/null || true
```

随后我在外部终端完成了 Miniconda 卸载。Codex 没有记录外部终端中实际执行的卸载命令，所以这里不补写一条事后猜测的命令。

卸载完成后，我重新查询了 `conda` 和 `python3`，也检查了几个常见的安装位置。结果显示，Miniconda 本体已经移除，系统默认的 `python3` 回到了系统路径。当前 shell 里仍有卸载前留下的 Conda 环境变量，这些值来自已经启动的进程，不能据此认定安装目录仍然存在。后续扫描还发现了旧 Python 包和失效的命令入口。

```bash
command -v conda
command -v python3
readlink -f "$(command -v python3)"
python3 --version
```

## 清理失效的 Python 文件

检查结果显示，`~/.local/lib/python3.7` 占了约 2.8 GiB，但系统中已经找不到 Python 3.7。`~/.local/lib/python3.9` 约有 14 MiB，对应的 Miniconda Python 也已经删除。`~/.local/bin` 中还有 34 个命令，它们指向已经不存在的 Miniconda 或 `colab_env`。

这里的判断依据来自两项检查。第一项是查询系统还能找到哪些 Python 解释器。第二项是读取 `~/.local/bin` 中每个脚本的首行，检查 shebang 指向的解释器文件是否存在。

```bash
for name in python python3 python3.7 python3.8 python3.9; do
  printf '%s=' "$name"
  command -v "$name" 2>/dev/null || printf 'not found\n'
done

for file in "$HOME"/.local/bin/*; do
  [ -f "$file" ] || continue
  IFS= read -r first_line < "$file" || true
  case "$first_line" in
    '#!'*)
      interpreter=${first_line#\#!}
      interpreter=${interpreter%% *}
      [ -e "$interpreter" ] || printf '%s -> %s\n' "$file" "$interpreter"
      ;;
  esac
done
```

最终删除了这些失效内容。

```text
~/.local/lib/python3.7
~/.local/lib/python3.9
~/.local/include/python3.7m
~/.local/include/python3.10
~/.local/bin 中失效的命令入口
```

清理后，`~/.local` 从约 2.8 GiB 降到 14 MiB。目录本身被保留下来，空的 `bin`、`lib` 和 `include` 目录仍可供以后安装用户级程序使用。

## 清理 VS Code Server 缓存

`~/.vscode-server` 最初约有 1.2 GiB。我继续查看了两层目录、Server 版本和扩展列表，再确定清理范围。

```bash
du -sh "$HOME/.vscode-server"
du -x -h --max-depth=2 "$HOME/.vscode-server" 2>/dev/null | sort -h
find "$HOME/.vscode-server/bin" -maxdepth 1 -mindepth 1 \
  -type d -printf '%TY-%Tm-%Td %TH:%TM\t%f\n' | sort
find "$HOME/.vscode-server/extensions" -maxdepth 1 -mindepth 1 \
  -type d -printf '%TY-%Tm-%Td\t%f\n' | sort
```

当前使用的 Server 程序约占 689 MiB，远程扩展约占 167 MiB，这些内容仍在使用。最终列入清理范围的是扩展安装包缓存、历史日志和几项可以自动重建的缓存。

这一步清理了约 299 MiB，`~/.vscode-server` 从 1.2 GiB 降到约 869 MiB。当前 Server、已安装扩展、用户配置和编辑历史都被保留。

## 再次扫描

完成以上操作后，用户主目录 `~` 的占用从约 10 GiB 降到 2.4 GiB，共减少约 7.6 GiB。整个 Linux 文件系统已经使用的空间从约 14 GiB 降到 5.6 GiB。

重新扫描 WSL2 根文件系统后，各部分占用大致如下。

| 目录 | 大小 | 主要内容 |
| --- | --- | --- |
| `/home` | 2.3 GiB | 用户文件和开发工具 |
| `/usr` | 1.9 GiB | 系统程序和运行库 |
| `/var` | 880 MiB | APT、Snap、日志和缓存 |
| `/opt` | 331 MiB | Google Chrome |

扫描还找到了一个约 115 MiB 的 Metals 日志。它位于 Docker 的共享目录中，文件属于 `root`，很可能由容器内的进程生成。考虑到容器挂载和文件归属，这个日志没有在宿主系统中强行删除。

## Linux 内部空间和 Windows VHDX 大小

上面的数字都来自 Linux 内部。`du` 统计目录和文件占用，`df` 显示 ext4 文件系统的容量、已用空间和可用空间。清理前看到的 251 GiB 是这个文件系统可以使用的容量。Windows 为 Ubuntu 实际占用的磁盘空间要查看 VHDX 文件的物理大小。

WSL2 把发行版文件保存在动态扩展的 `ext4.vhdx` 中。这个文件会随着写入增长。Linux 中删除文件以后，`df` 能确认 ext4 内部多出了可用空间，Windows 上的 VHDX 文件却不一定立即缩小。微软对[动态 VHD 的说明](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/compact-vdisk)也指出，这类文件会在写入时增长，删除文件后不会自动减小物理文件尺寸。

因此，这次记录中的 7.6 GiB 只表示主目录占用的减少量，不能当成 Windows 磁盘同步增加了 7.6 GiB 可用空间。当时没有记录 `ext4.vhdx` 清理前后的文件大小，也没有执行 `wsl --shutdown` 或 VHD 压缩。需要处理 Windows 侧空间时，可以另行参考微软的 [WSL 磁盘空间管理文档](https://learn.microsoft.com/en-us/windows/wsl/disk-space)。

后续若要在 Windows 侧压缩 VHDX，可以保存 WSL 中尚未完成的工作，退出可能占用该发行版的程序，再以管理员身份打开 PowerShell。下面这组命令先从注册表取得发行版的 VHDX 路径，记录压缩前后的文件大小，再调用 Hyper-V 模块提供的 `Optimize-VHD`。这组命令是补充方法，并非这次清理时执行过的操作。

```powershell
$distro = '<distribution-name>'
$basePath = (Get-ChildItem HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss |
  Where-Object { $_.GetValue('DistributionName') -eq $distro }).GetValue('BasePath')
$vhdPath = Join-Path $basePath 'ext4.vhdx'

Get-Item $vhdPath | Select-Object FullName, Length
wsl.exe --shutdown
Optimize-VHD -Path $vhdPath -Mode Full
Get-Item $vhdPath | Select-Object FullName, Length
```

`Optimize-VHD` 需要系统提供 Hyper-V PowerShell 模块，目标 VHDX 也必须处于未挂载或只读挂载状态。`wsl.exe --shutdown` 会停止所有正在运行的 WSL 发行版。微软的 [`Optimize-VHD` 文档](https://learn.microsoft.com/en-us/powershell/module/hyper-v/optimize-vhd?view=windowsserver2025-ps)还说明，压缩操作即使成功，文件大小也可能没有变化。

## 后续复查

8 月 27 日再次扫描时，WSL 根盘使用约 6.4 GiB，仍然只占总容量的 3%。那次又清理了 npm 缓存和 APT 下载缓存。执行 `sudo apt clean` 后，`/var` 从约 894 MiB 降到 706 MiB，其中 `/var/cache/apt` 只剩约 36 KiB。

这两次清理留下的经验很具体。先用 `du` 和 `find` 找到占用，再确认文件属于哪个工具、依赖是否仍然存在、内容能否自动重建。空间数字也要注明测量位置。Linux 内部多出可用空间，只能证明 Linux 文件已经释放，Windows 侧还要单独查看 VHDX 文件。
