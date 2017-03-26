#!/usr/bin/env bash

brew update
brew install vim --override-system-vim

curl https://j.mp/spf13-vim3 -L -o - | sh

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../.."

# clean up previous files
if [ -e "$HOME/.vimrc.local" ]; then
  rm ~/.vimrc.local
fi
if [ -e "$HOME/.vimrc.before.local" ]; then
  rm ~/.vimrc.before.local
fi
if [ -e "$HOME/.vimrc.bundles.local" ]; then
  rm ~/.vimrc.bundles.local
fi

ln -s "$ROOT/configs/.vimrc.local" ~/.vimrc.local
ln -s "$ROOT/configs/.vimrc.before.local" ~/.vimrc.before.local
ln -s "$ROOT/configs/.vimrc.bundles.local" ~/.vimrc.bundles.local
