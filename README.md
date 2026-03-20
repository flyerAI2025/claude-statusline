<div align="center">

# claude-statusline

**Batteries-included status line for Claude Code**

One file. Pure bash + jq. macOS only. Copy → done.

<img src="assets/demo.svg" alt="demo" width="764">

[Install](#install) · [Features](#features) · [Configure](#configuration) · [Rate Alert](#rate-alert)

**[中文文档](README.zh.md)**

</div>

---

## Install

```bash
git clone https://github.com/flyerAI2025/claude-statusline.git
cd claude-statusline && bash install.sh
```

Or manually: copy `claude-statusline.sh` → `~/.claude/statusline-command.sh`, add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

**Requires:** `jq` (`brew install jq`) · macOS · Claude Code ≥ 2.1.81

## Features

### Color system

A 4-color rotation (Bold Green → Bold Magenta → Bold Blue → Bold Cyan) ensures every adjacent widget has a **visually distinct** hue — works on both light and dark terminal themes.

Dynamic widgets (context, cost, quota, CPU) switch to **Bold Yellow** at warning threshold and **Bold Red** at critical threshold.

### Widgets

| Widget | Default | Color (ok) | Warning | Critical |
|---|---|---|---|---|
| Directory | Off | Bold Blue | — | — |
| Git branch | Off | Bold Green | — | — |
| Session | On | Bold Cyan | — | — |
| Model | On | Bold Magenta | — | — |
| Effort | On | Bold Green | — | — |
| Context | On | Bold Blue | ≥50% Yellow | ≥80% Red |
| Output style | On | Bold Green | — | — |
| Cost | On | Bold Cyan | ≥$1 Yellow | ≥$5 Red |
| Lines changed | Off | Bold Magenta | — | — |
| Duration | Off | Bold Blue | — | — |
| 5h quota | On | Bold Green | ≥50% Yellow | ≥80% Red |
| 7d quota | On | Bold Magenta | ≥50% Yellow | ≥80% Red |
| CPU | On | Bold Blue | ≥50% Yellow | ≥80% Red |
| Memory | On | Bold Cyan | — | — |
| Time | On | Bold Green | — | — |
| Vim mode | Auto | `[N]` Magenta / `[I]` Green | — | — |

### What makes this different

- **One file, zero runtime** — no npm, no compilation, no daemon
- **4-color rotation** — every adjacent widget guaranteed different hue, light & dark theme safe
- **Rate alert** — `!` warns when you're consuming quota faster than sustainable
- **Everything toggleable** — one env var per widget, show exactly what you need
- **Optimized** — single `jq` call for JSON parsing, ~100ms on Apple Silicon

## Configuration

Toggle any widget via env vars. Add to `~/.zshrc`:

```bash
# Widgets (1 = show, 0 = hide)
export CSL_SHOW_CWD=1        # Working directory (default: 0)
export CSL_SHOW_GIT=1        # Git branch (default: 0)
export CSL_SHOW_SESSION=1    # Session name (default: 1)
export CSL_SHOW_MODEL=1      # Model name (default: 1)
export CSL_SHOW_EFFORT=1     # Effort level H/M/L (default: 1)
export CSL_SHOW_CONTEXT=1    # Context window (default: 1)
export CSL_SHOW_STYLE=1      # Output style (default: 1)
export CSL_SHOW_COST=1       # Session cost (default: 1)
export CSL_SHOW_LINES=1      # Lines changed (default: 0)
export CSL_SHOW_DURATION=1   # Session duration (default: 0)
export CSL_SHOW_USAGE=1      # 5h/7d quota (default: 1)
export CSL_SHOW_PACING=1     # Rate alert ! (default: 1)
export CSL_SHOW_CPU=1        # CPU usage (default: 1)
export CSL_SHOW_MEM=1        # Memory (default: 1)
export CSL_SHOW_TIME=1       # Clock (default: 1)

# Other
export CSL_SEP="│"           # Separator (default: │)
export CSL_NCPU=8            # CPU core count (default: auto-detect)
export CSL_MEMTOTAL=16       # Total memory in GB (default: auto-detect)
```

### Minimal example

```bash
export CSL_SHOW_CPU=0 CSL_SHOW_MEM=0 CSL_SHOW_TIME=0
```

## Rate Alert

When `CSL_SHOW_PACING=1`, a red **`!`** appears after the quota percentage if you're consuming faster than the sustainable pace for the remaining time window.

**How it works:** compares your actual usage with where you *should* be at this point in the window. If you're more than 15% ahead of the sustainable pace, `!` appears.

```
5h window = 5 hours total
You've used 2 hours, 3 hours left
Usage: 70%  →  Expected at this point: ~40%
→  30% ahead of pace → 5h:70%! (red !)
```

No indicator means you're on pace or have headroom.

## Technical Details

### Version requirement

Claude Code ≥ 2.1.81 is required. This version embeds `rate_limits` (5h/7d quota data) directly in the statusline JSON, eliminating the need for a separate API call.

### Performance

- 1 `jq` call for all JSON parsing (model, context, cost, quota)
- `\x1e` (Record Separator) as field delimiter — handles empty fields correctly
- CPU via `ps -A -o %cpu` summed across all cores
- No spaces in output — model name spaces replaced with `·`
- ~100ms per invocation on Apple Silicon

## Update

```bash
cd claude-statusline && git pull && bash install.sh
```

## Uninstall

```bash
rm ~/.claude/statusline-command.sh
```

Then remove the `statusLine` block from `~/.claude/settings.json`.

## License

[MIT](LICENSE)
