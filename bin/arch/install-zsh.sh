#!/usr/bin/env bash

sudo pacman -S zsh --noconfirm
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

cp $HOME/.bash_profile $HOME/.zprofile

if [ -e "${HOME}/.zshrc" ]; then
	rm $HOME/.zshrc
fi
ln -s "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/../../configs/.zshrc $HOME/.zshrc

touch $HOME/.zshrc.local

zsh
