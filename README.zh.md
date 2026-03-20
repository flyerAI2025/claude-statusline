<div align="center">

# claude-statusline

**Claude Code 全功能状态栏**

一个文件，纯 bash + jq，仅 macOS，复制即用。

<img src="assets/demo.png" alt="demo" width="1060">

[安装](#安装) · [功能](#功能) · [配置](#配置) · [超速警告](#超速警告)

**[English](README.md)**

</div>

---

## 安装

```bash
git clone https://github.com/flyerAI2025/claude-statusline.git
cd claude-statusline && bash install.sh
```

或手动：复制 `claude-statusline.sh` 到 `~/.claude/statusline-command.sh`，在 `~/.claude/settings.json` 加入：

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

**依赖：** `jq`（`brew install jq`）· macOS · Claude Code ≥ 2.1.81

## 功能

### 状态栏解剖

```
flyertube:main !19?9│Opus·4.6│X│390k/1000k(39%)│$507.25│5h:2%@19:00│7d:37%@04/05·12:00│cpu:18%│3.0/24G│15:17
```

| 片段 | 组件 | 颜色规则 |
|---|---|---|
| `flyertube:main` | Git 仓库:分支 | 绿 = 干净 · 黄 = 有改动 · 红 = 有冲突 |
| `!19?9` | Git 指示符 | 绿 `+N` 已暂存 · 红 `!N` 已修改 · 灰 `?N` 未跟踪 · 红 `✘N` 冲突 · 绿 `↑N` 领先 · 红 `↓N` 落后 |
| `Opus·4.6` | 模型 | 洋红 |
| `X` | Effort（Max） | 绿 |
| `390k/1000k(39%)` | 上下文窗口 | 蓝 → ≥50% 黄 → ≥80% 红 |
| `$507.25` | 会话费用 | 青 → ≥$1 黄 → ≥$5 红 |
| `5h:2%@19:00` | 5 小时配额 + 重置时间 | 绿 → ≥50% 黄 → ≥80% 红 · 灰色重置时间 |
| `7d:37%@04/05·12:00` | 7 天配额 + 重置时间 | 洋红 → ≥50% 黄 → ≥80% 红 · 灰色重置时间 |
| `cpu:18%` | CPU | 蓝 → ≥50% 黄 → ≥80% 红 |
| `3.0/24G` | 内存 | 青 |
| `15:17` | 时间 | 绿 |

其他组件（默认关闭）：**工作目录**、**改动行数**、**会话时长**。自动检测：**Vim 模式**（`[N]`/`[I]`）。

### 配色系统

4 色轮换（绿 → 洋红 → 蓝 → 青）确保每个**相邻组件**颜色截然不同，亮色/暗色终端主题均适配。

动态组件（上下文、费用、配额、CPU）在警告阈值切换为**黄色**，临界阈值切换为**红色**。

### Git 状态

分支名颜色反映工作区状态——**绿色**干净、**黄色**有改动、**红色**有冲突。紧凑指示符跟在分支名后面：

| 状态 | 分支颜色 | 显示指示符 |
|---|---|---|
| 干净 | 绿 | — |
| 有修改 / 未跟踪 | 黄 | `!N` `?N` |
| 有暂存 | 绿 | `+N` |
| 有冲突 | 红 | `✘N` |
| 领先 / 落后远端 | （不变） | `↑N` `↓N` |

全部信息来自一次 `git status --porcelain=v2 --branch` 调用。

## 配置

通过环境变量控制，加到 `~/.zshrc`：

```bash
# 组件开关（1 = 显示，0 = 隐藏）
export CSL_SHOW_CWD=1        # 工作目录（默认：0）
export CSL_SHOW_GIT=1        # Git 状态（默认：1）
export CSL_SHOW_MODEL=1      # 模型名（默认：1）
export CSL_SHOW_EFFORT=1     # Effort X/H/M/L（默认：1）
export CSL_SHOW_CONTEXT=1    # 上下文窗口（默认：1）
export CSL_SHOW_COST=1       # 会话费用（默认：1）
export CSL_SHOW_LINES=1      # 改动行数（默认：0）
export CSL_SHOW_DURATION=1   # 会话时长（默认：0）
export CSL_SHOW_USAGE=1      # 5h/7d 配额（默认：1）
export CSL_SHOW_PACING=1     # 超速警告 !（默认：1）
export CSL_SHOW_CPU=1        # CPU 用量（默认：1）
export CSL_SHOW_MEM=1        # 内存（默认：1）
export CSL_SHOW_TIME=1       # 时钟（默认：1）

# 其他
export CSL_SEP="│"           # 分隔符（默认：│）
export CSL_NCPU=8            # CPU 核心数（默认：自动检测）
export CSL_MEMTOTAL=16       # 总内存 GB（默认：自动检测）
```

### 精简示例

```bash
export CSL_SHOW_CPU=0 CSL_SHOW_MEM=0 CSL_SHOW_TIME=0
```

## 超速警告

开启 `CSL_SHOW_PACING=1` 时，如果配额消耗速度超过可持续节奏，会在百分比后显示红色 **`!`**。

**原理：** 比较实际用量与当前时间点的预期用量。偏差超过 15% 则触发警告。

```
5h 窗口 = 5 小时
已过 2 小时，剩余 3 小时
实际用量: 70%  →  预期: ~40%
→  超出 30%  →  5h:70%!（红色叹号）
```

不显示叹号 = 节奏正常或有余量。

## 技术细节

- **版本要求**：Claude Code ≥ 2.1.81（该版本起 statusline JSON 内嵌 `rate_limits`，无需额外 API 调用）
- **性能**：1 次 jq 解析所有 JSON 数据，1 次 `git status` 获取全部仓库状态（分支、暂存、修改、未跟踪、领先/落后），Apple Silicon 约 100ms/次
- **CPU 读取**：`ps -A -o %cpu` 汇总所有核心用量
- **无空格输出**：模型名中的空格替换为 `·`（如 `Sonnet·4.6`），括号后缀（如 `(1M context)`）自动去除以避免与上下文组件重复，日期分隔符同理
- **分隔符**：`\x1e`（Record Separator）作字段分隔符，正确处理空字段

## 更新

```bash
cd claude-statusline && git pull && bash install.sh
```

## 卸载

```bash
rm ~/.claude/statusline-command.sh
```

然后从 `~/.claude/settings.json` 中移除 `statusLine` 配置块。

## 许可证

[MIT](LICENSE)
