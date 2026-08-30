---
layout: post
title: "一次 WSL2 磁盘清理记录"
date: 2026-08-30 00:00:00 +0800
tags:
  - WSL2
  - Linux
  - 磁盘清理
---

2026 年 8 月 15 日，我检查了 WSL2 中 Ubuntu 发行版的磁盘占用。清理前，用户主目录 `~` 大约占了 10 GiB，整个 Linux 文件系统已经使用约 14 GiB。磁盘总容量有 251 GiB，当时并不缺空间。这次检查的目的，是找出多年开发留下的大目录，并清掉已经确定不用的内容。

## 第一次扫描

扫描把隐藏目录也算了进去。Home 目录中占用较大的位置如下。

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

`~/nltk_data` 已经不再使用，所以先删除了这个目录。

```text
~/nltk_data
```

这一步释放约 3.3 GiB。Home 目录从约 10 GiB 降到 6.8 GiB。

## 卸载 Miniconda 并检查残留

`~/miniconda3` 大约占 1.5 GiB，其中有 `base` 和 `colab_env` 两个环境。会话中先检查了 Conda 初始化配置和用户状态目录，随后我在外部终端完成了 Miniconda 卸载。

Codex 没有记录外部终端中实际执行的卸载命令，因此这里只保留能够确认的结果。卸载完成后，系统默认的 `python3` 回到了系统路径，Miniconda 本体已经移除。后续检查仍然发现了旧 Python 包和失效的命令入口。

## 清理失效的 Python 文件

检查结果显示，`~/.local/lib/python3.7` 占了约 2.8 GiB，但系统中已经没有 Python 3.7。`~/.local/lib/python3.9` 约有 14 MiB，对应的 Miniconda Python 也已经删除。`~/.local/bin` 中还有 34 个命令，它们指向已经不存在的 Miniconda 或 `colab_env`。

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

`~/.vscode-server` 最初约有 1.2 GiB。当前使用的 Server 程序约占 689 MiB，远程扩展约占 167 MiB，这些内容仍在使用。适合清理的是扩展安装包缓存、历史日志和几项可以自动重建的缓存。

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

## 后续复查

8 月 27 日再次扫描时，WSL 根盘使用约 6.4 GB，仍然只占总容量的 3%。那次又清理了 npm 缓存和 APT 下载缓存。执行 `sudo apt clean` 后，`/var` 从约 894 MB 降到 706 MB，其中 `/var/cache/apt` 只剩约 36 KB。

这两次记录目前都来自 Codex 留下的本地会话日志。第一轮清理的操作和数值比较完整，适合继续补成正式文章。Miniconda 的实际卸载命令发生在外部终端，发布前还需要根据当时使用的方法补充，或者只保留检查结果。
