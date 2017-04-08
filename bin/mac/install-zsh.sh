#!/usr/bin/env bash

sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Check if zshrc exists and back it up if this is the initial install
if [ -e "$HOME/.zshrc" ]; then
  if [ ! -e "$HOME/.zshrc.local" ]; then
    mv "$HOME/.zshrc" "$HOME/.zshrc-backup"
    touch "$HOME/.zshrc.local"
  fi

  rm "$HOME/.zshrc"
fi

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../.."
ln -s "$ROOT/configs/.zshrc" "$HOME/.zshrc"

zsh
