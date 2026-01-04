# Agents

This directory contains AI agents that can be used across all projects via the `--plugin-dir` flag.

## Available Agents

| Agent | Purpose |
|-------|---------|
| `code-reviewer` | Git-based PR review with enterprise-grade analysis |
| `task-master` | Worktree task execution with scope enforcement |
| `multitasker` | Parallel worktree management |
| `agentic-workflow` | Multi-agent coordination architecture |

## Agent File Format

All agents follow the Claude Code standard format with YAML frontmatter:

```markdown
---
name: agent-identifier
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
tools: ["Read", "Write", "Bash", "Grep"]
---

[System prompt content]
```

### Required Fields

| Field | Description |
|-------|-------------|
| `name` | Lowercase identifier with hyphens (e.g., `code-reviewer`) |
| `description` | Starts with "Use this agent when..." with examples |
| `model` | Usually `inherit` to use parent model |
| `color` | Visual identifier: `blue`, `green`, `orange`, `red`, `purple` |

### Optional Fields

| Field | Description |
|-------|-------------|
| `tools` | Array of allowed tools: `["Read", "Write", "Bash", "Grep", "Glob"]` |

## Adding New Agents

1. Create a new `.md` file in this directory
2. Add YAML frontmatter with required fields
3. Include `<example>` blocks showing when the agent triggers
4. Write the system prompt content

The agent is immediately available in all projects using this plugin.

## Usage

Agents are auto-discovered when using the plugin:

```bash
claude --plugin-dir ~/ai
```

Claude Code will automatically invoke agents based on their `description` field, or you can reference them explicitly.
