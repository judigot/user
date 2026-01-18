Locked Plan (Single‑action bootstrap, aliases preserved)
1. Modularize .devrc into .devrc.d/ with two‑digit ordered modules:
   - 00-core.sh, 10-aliases.sh, 20-updater.sh, 30-git.sh, 40-terraform.sh, 50-node.sh, 60-ai.sh, 90-misc.sh
2. Keep .devrc minimal: env vars + autoload all ~/.devrc.d/*.sh (barrel‑style).
3. Preserve aliases:
   - loadAliasFile stays intact, moved into 10-aliases.sh
   - .devrc still triggers alias loading.
4. Update load-devrc.sh to download:
   - ~/.devrc
   - ~/ALIAS
   - all .devrc.d/*.sh (so the one‑liner still works in one move)
5. Update updateUserEnv to refresh .devrc.d/*.sh alongside .devrc + ALIAS (still safe).
6. Keep updaterFull behavior unchanged (confirmation + .bashrc overwrite).
7. Add .devrc.d/ to DOTFILES so it syncs like .devrc.
8. Docs: add a short note in README that .devrc autoloads .devrc.d/ (no change to usage snippets).
9. Verify parity (source .devrc, check key aliases/functions), then commit + sync.
When you’re ready, say “proceed with implementation.”