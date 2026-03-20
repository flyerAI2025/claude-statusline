<div align="center">

# claude-statusline

**Claude Code 全功能状态栏**

一个文件，纯 bash + jq，仅 macOS，复制即用。

<img src="assets/demo.svg" alt="demo" width="764">

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

### 配色系统

4 色轮换（粗体绿 → 粗体洋红 → 粗体蓝 → 粗体青）确保每个**相邻组件**颜色截然不同，亮色/暗色终端主题均适配。

动态组件（上下文、费用、配额、CPU）在警告阈值切换为**粗体黄**，临界阈值切换为**粗体红**。

### 组件一览

| 组件 | 默认 | 正常色 | 警告 | 临界 |
|---|---|---|---|---|
| 工作目录 | 关 | 粗体蓝 | — | — |
| Git 分支 | 关 | 粗体绿 | — | — |
| 会话名 | 开 | 粗体青 | — | — |
| 模型 | 开 | 粗体洋红 | — | — |
| Effort | 开 | 粗体绿 | — | — |
| 上下文 | 开 | 粗体蓝 | ≥50% 黄 | ≥80% 红 |
| 输出模式 | 开 | 粗体绿 | — | — |
| 费用 | 开 | 粗体青 | ≥$1 黄 | ≥$5 红 |
| 改动行数 | 关 | 粗体洋红 | — | — |
| 会话时长 | 关 | 粗体蓝 | — | — |
| 5h 配额 | 开 | 粗体绿 | ≥50% 黄 | ≥80% 红 |
| 7d 配额 | 开 | 粗体洋红 | ≥50% 黄 | ≥80% 红 |
| CPU | 开 | 粗体蓝 | ≥50% 黄 | ≥80% 红 |
| 内存 | 开 | 粗体青 | — | — |
| 时间 | 开 | 粗体绿 | — | — |
| Vim 模式 | 自动 | `[N]` 洋红 / `[I]` 绿 | — | — |

## 配置

通过环境变量控制，加到 `~/.zshrc`：

```bash
export CSL_SHOW_CWD=1        # 显示工作目录（默认关）
export CSL_SHOW_EFFORT=0     # 隐藏 effort（默认开）
export CSL_SHOW_LINES=1      # 显示改动行数（默认关）
export CSL_SHOW_DURATION=1   # 显示会话时长（默认关）
export CSL_SHOW_CPU=0        # 隐藏 CPU
export CSL_SHOW_MEM=0        # 隐藏内存
export CSL_SEP="·"           # 自定义分隔符（默认 │）
export CSL_NCPU=8            # CPU 核心数（默认自动检测）
export CSL_MEMTOTAL=16       # 总内存 GB（默认自动检测）
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
- **性能**：1 次 jq 解析所有数据（模型、上下文、费用、配额），Apple Silicon 约 100ms/次
- **CPU 读取**：`ps -A -o %cpu` 汇总所有核心用量
- **无空格输出**：模型名中的空格替换为 `·`（如 `Sonnet·4.6`），日期分隔符同理
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
