# Project Instructions

## IDE Setup

### Claude Code

Global settings from `~/ai` are automatically loaded via shell function:

```sh
claude   # Automatically uses --plugin-dir ~/ai
```

For project-specific agents, add the local plugin:

```sh
claude --plugin-dir ~/ai --plugin-dir .
```

### Cursor IDE

- Global rules: Maintained in `~/ai/settings/rules.md` (not duplicated here)
- Project agents: Reference with `@agents/<agent>.md`

## Available Agents

See `agents/*.md` files.

## Directory Structure

```
project/
├── .cursor/                  # Reusable template
│   └── rules/
│       ├── global-agents/
│       │   └── RULE.md       # References ~/ai (always applied)
│       └── project-agents/
│           └── RULE.md       # References agents/README.md
├── agents/                   # Project-specific agents
│   ├── README.md             # Agent documentation
│   └── agent-template.md     # Template for new agents
├── AGENTS.md                 # This file
└── CLAUDE.md                 # Entry point
```

## Global Resources

@~/ai/README.md

## Notes for AI Assistants

- Check agent descriptions to understand when to invoke them
- Follow coding standards from `~/ai/settings/rules.md`

