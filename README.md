<div align="center">

# claude-statusline

**Batteries-included status line for Claude Code**

One file. Pure bash + jq. macOS only. Copy → done.

<img src="assets/demo.png" alt="demo" width="1060">

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

### Anatomy

```
flyertube:main !19?9│Opus·4.6│X│390k/1000k(39%)│$507.25│5h:2%@19:00│7d:37%@04/05·12:00│cpu:18%│3.0/24G│15:17
```

| Segment | Widget | Color rules |
|---|---|---|
| `flyertube:main` | Git repo:branch | Green = clean · Yellow = dirty · Red = conflict |
| `!19?9` | Git indicators | Green `+N` staged · Red `!N` modified · Gray `?N` untracked · Red `✘N` conflict · Green `↑N` ahead · Red `↓N` behind |
| `Opus·4.6` | Model | Magenta |
| `X` | Effort (Max) | Green |
| `390k/1000k(39%)` | Context window | Blue → Yellow ≥50% → Red ≥80% |
| `$507.25` | Session cost | Cyan → Yellow ≥$1 → Red ≥$5 |
| `5h:2%@19:00` | 5h quota + reset time | Green → Yellow ≥50% → Red ≥80% · Gray reset time |
| `7d:37%@04/05·12:00` | 7d quota + reset time | Magenta → Yellow ≥50% → Red ≥80% · Gray reset time |
| `cpu:18%` | CPU | Blue → Yellow ≥50% → Red ≥80% |
| `3.0/24G` | Memory | Cyan |
| `15:17` | Time | Green |

Additional widgets (off by default): **Directory**, **Lines changed**, **Duration**. Auto-detected: **Vim mode** (`[N]`/`[I]`).

### Color system

A 4-color rotation (Green → Magenta → Blue → Cyan) ensures every adjacent widget has a **visually distinct** hue — works on both light and dark terminal themes.

Dynamic widgets (context, cost, quota, CPU) switch to **Yellow** at warning threshold and **Red** at critical threshold.

### Git status

Branch name color reflects working tree state — **green** when clean, **yellow** when dirty, **red** on conflict. Compact indicators follow the branch name:

| State | Branch color | Indicators |
|---|---|---|
| Clean | Green | — |
| Modified / untracked | Yellow | `!N` `?N` |
| Staged | Green | `+N` |
| Conflict | Red | `✘N` |
| Ahead / behind remote | (unchanged) | `↑N` `↓N` |

All derived from a single `git status --porcelain=v2 --branch` call.

### What makes this different

- **One file, zero runtime** — no npm, no compilation, no daemon
- **4-color rotation** — every adjacent widget guaranteed different hue, light & dark theme safe
- **Git-colored status** — branch color + compact indicators match git conventions at a glance
- **Rate alert** — `!` warns when you're consuming quota faster than sustainable
- **Everything toggleable** — one env var per widget, show exactly what you need
- **Optimized** — single `jq` call for JSON, single `git status` for all repo state, ~100ms on Apple Silicon

## Configuration

Toggle any widget via env vars. Add to `~/.zshrc`:

```bash
# Widgets (1 = show, 0 = hide)
export CSL_SHOW_CWD=1        # Working directory (default: 0)
export CSL_SHOW_GIT=1        # Git status (default: 1)
export CSL_SHOW_MODEL=1      # Model name (default: 1)
export CSL_SHOW_EFFORT=1     # Effort level X/H/M/L (default: 1)
export CSL_SHOW_CONTEXT=1    # Context window (default: 1)
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
- 1 `git status --porcelain=v2 --branch` call for all repo state (branch, staged, dirty, untracked, ahead/behind)
- `\x1e` (Record Separator) as field delimiter — handles empty fields correctly
- CPU via `ps -A -o %cpu` summed across all cores
- No spaces in output — model name spaces replaced with `·`, parenthetical suffix (e.g. `(1M context)`) stripped to avoid redundancy with context widget
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
