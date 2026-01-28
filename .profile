# ~/.profile: executed by Bourne-compatible login shells.

# Ensure .bashrc is sourced in ALL shell types (interactive and non-interactive)
export BASH_ENV="$HOME/.bashrc"

# Source .bashrc for interactive login shells
if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi

mesg n 2> /dev/null || true
