#!/bin/bash

cb="$(date +%s 2>/dev/null || echo 0)"
base_url="https://raw.githubusercontent.com/judigot/user/main"

curl -fsSL "$base_url/.snippetsrc?cb=$cb" -o "$HOME/.snippetsrc" \
    && curl -fsSL "$base_url/ALIAS?cb=$cb" -o "$HOME/ALIAS" \
    && . "$HOME/.snippetsrc" \
    && { grep -q '#<SNIPPETS>' "$HOME/.bashrc" 2>/dev/null || printf '%s\n' '#<SNIPPETS>' '[[ -f "$HOME/.snippetsrc" ]] && source "$HOME/.snippetsrc"' '#</SNIPPETS>' >> "$HOME/.bashrc"; }
