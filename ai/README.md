# AI — Centralized Claude Code Plugin

A centralized Claude Code plugin containing agents, skills, hooks, and coding rules. Use this across **all your projects** without duplicating setup.

## Quick Start

### 1. Clone to a permanent location

```sh
git clone https://github.com/judigot/ai.git ~/ai
```

### 2. Create a shell alias

Add to your `.bashrc`, `.zshrc`, or shell config:

```sh
alias cc='claude --plugin-dir ~/ai'
```

Reload your shell:

```sh
source ~/.bashrc
```

### 3. Use in any project

```sh
cd /path/to/any/project
cc
```

All your agents, skills, hooks, and rules are now available!

## Directory Structure

```
ai/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest (required)
├── agents/                   # Agent definitions (.md files)
│   ├── code-reviewer.md      # Git-based PR review
│   ├── task-master.md        # Worktree task execution
│   ├── multitasker.md        # Parallel worktree management
│   └── agentic-workflow.md   # Multi-agent coordination
├── skills/                   # Specialized skills (subdirectories)
│   ├── lint-master/
│   │   └── SKILL.md          # Multi-tool linting workflow
│   └── test-master/
│       └── SKILL.md          # Testing infrastructure
├── hooks/
│   └── hooks.json            # SessionStart, PreToolUse, Stop hooks
├── commands/                 # Slash commands (.md files)
├── scripts/                  # Helper scripts
├── settings/                 # Personal settings (compartmentalized)
│   └── rules.md              # Coding rules loaded on session start
├── CLAUDE.md                 # Plugin entry point
└── README.md
```

## How It Works

### Personal Settings (Compartmentalized)

Your personal coding rules are stored in `settings/rules.md`, separate from `~/.claude`. This provides:
- **Single source of truth**: One repository for all global settings
- **Version control**: Track changes to your rules over time
- **Portability**: Same settings across all machines

The `hooks/hooks.json` loads your rules on every session start:

```json
{
  "SessionStart": [
    {
      "matcher": "*",
      "hooks": [
        {
          "type": "command",
          "command": "cat ${CLAUDE_PLUGIN_ROOT}/settings/rules.md"
        }
      ]
    }
  ]
}
```

### Global Plugin Loading

The `--plugin-dir` flag tells Claude Code to load this plugin for any project:

```sh
claude --plugin-dir ~/ai
```

This applies your agents, skills, hooks, and settings globally without copying files to each project.

## Available Agents

| Agent | Purpose |
|-------|---------|
| `code-reviewer` | Git-based PR review with enterprise-grade analysis |
| `task-master` | Worktree task execution with scope enforcement |
| `multitasker` | Parallel worktree management |
| `agentic-workflow` | Multi-agent coordination architecture |

## Available Skills

| Skill | Purpose |
|-------|---------|
| `lint-master` | Multi-tool linting workflow (ESLint > Oxlint > Biome) |
| `test-master` | Testing infrastructure and implementation |

## Sprint Modes (Choose One Per Sprint)

You can run this plugin in two modes depending on task overlap and how hands-off you want to be.

### Mode A: Parallel Worktrees (Fastest When Tasks Do Not Overlap)

- Best for many small, independent tasks.
- One worktree per task; one agent per worktree.
- Uses `task-master` and `multitasker`.

**Start here:** `ai/scripts/README.md` → "CLI-Native Worktree Workflow"

### Mode B: Sequential Ralph Loop (Safest When Tasks Overlap)

- Best for tasks that touch the same files or require strict sequencing.
- Uses a single loop that runs one small task per iteration.
- Ralph memory is persisted in git, `progress.txt`, and `prd.json`.

**Start here:** `ai/scripts/ralph/` and `ai/scripts/README.md` → "Ralph Loop Workflow"

## Combining with Project-Specific Config

Local projects can have their own settings that extend the global ones:

```
my-project/
├── CLAUDE.md                 # Project-specific rules
├── .claude/
│   └── settings.local.json   # Project-specific settings
└── agents/                   # Project-specific agents (optional)
```

Claude Code loads in this order:
1. Global plugin (from `--plugin-dir`) ← This repository
2. Project `CLAUDE.md`
3. Local `.claude/` settings

## Updating

```sh
cd ~/ai
git pull
```

Changes apply to the next Claude Code session.

## Adding New Components

### New Agent

Create a new `.md` file in `agents/`:

```markdown
---
name: my-agent
description: Use this agent when [conditions]. Examples:

<example>
Context: [Situation]
user: "[Request]"
assistant: "[Response]"
<commentary>
[Why this agent triggers]
</commentary>
</example>

model: inherit
color: blue
tools: ["Read", "Write", "Bash"]
---

You are an expert at...

[Agent instructions here]
```

### New Skill

Create a new subdirectory in `skills/` with a `SKILL.md` file:

```
skills/
└── my-skill/
    └── SKILL.md
```

The skill file follows the same format as agents.

### New Command

Create a new `.md` file in `commands/` for slash commands.

## License

MIT
