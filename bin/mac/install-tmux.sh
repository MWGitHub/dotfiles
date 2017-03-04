#!/usr/bin/env bash

brew update
brew install tmux

# clean up previous files
if [ -e "$HOME/.tmux.conf" ]; then
  rm ~/.tmux.conf
fi
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  rm -rf ~/.tmux/plugins/tpm
fi

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../"
ln -s "$ROOT/configs/.tmux.conf" ~/.tmux.conf
tmux source ~/.tmux.conf

~/.tmux/plugins/tpm/bin/install_plugins
