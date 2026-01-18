# Project Instructions

## Repository Purpose

This repository (`judigot/user`) is the source of truth for personal dotfiles, AI tooling, and IDE scaffolding. It also contains the `project-core/` template that is synced to other projects.

## Agent Guidance

- Follow coding standards from `~/ai/settings/rules.md`.
- After making changes, run `./commit-and-sync.sh "<message>"`.
- Keep `README.md` updated when repo structure or workflows change.
- Avoid committing secrets (`.env`, credentials, API keys).
- Prefer editing existing files over adding new ones.
- Treat `project-core/` as the only scaffold source for new projects.
- Avoid deleting manifest files (`DOTFILES`, `PROJECT_CORE`, `IDE_FILES`, `UBUNTU`).
- When changing sync logic, update docs and manifest explanations.
- Keep `load-snippetsrc.sh` safe to source in the current shell (no `set -e` when sourced).
- Make minimal, request-scoped changes (avoid unrelated refactors).
- Keep root `AGENTS.md` repo-specific; template guidance belongs in `project-core/`.

## More Context

- See `README.md` for repository structure, usage, and setup details.
