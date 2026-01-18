# Project Instructions

## Repository Purpose

This repository (`judigot/user`) is the source of truth for personal dotfiles, AI tooling, and IDE scaffolding. It also contains the `project-core/` template that is synced to other projects.

## Key Scripts

### commit-and-sync.sh

Use `./commit-and-sync.sh "<message>"` after making changes.

- Commits and pushes this repo (`judigot/user`).
- Syncs dotfiles to the home directory based on `DOTFILES`.
- Syncs `ai/` to `~/ai` and pushes to `judigot/ai`.
- Syncs `project-core/` to `~/.apportable/cursor` and pushes to `judigot/project-core`.
- Syncs `ide/` to `~/.apportable/ide` and pushes to `judigot/ide`.
- Syncs WSL Ubuntu files listed in `UBUNTU`.

If no commit message is provided, it defaults to `chore: update user files`.

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

## Global Resources

@~/ai/README.md

## Notes for AI Assistants

- Follow coding standards from `~/ai/settings/rules.md`.
- After making changes, run `./commit-and-sync.sh "<message>"`.
