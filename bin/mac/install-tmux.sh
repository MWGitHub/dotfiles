#!/usr/bin/env bash

brew update
brew install tmux

rm -rf ~/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../"
ln -s "$ROOT/configs/.tmux.conf" ~/.tmux.conf
tmux source ~/.tmux.conf

~/.tmux/plugins/tpm/bin/install_plugins
