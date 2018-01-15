#!/usr/bin/env bash

sudo pacman -S --noconfirm tmux
sudo pacman -S --noconfirm xclip

if [ ! -d "${HOME}/.tmux/plugins/tpm" ]; then
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

if [ -e "${HOME}/.tmux.conf" ]; then
	rm $HOME/.tmux.conf
fi
ln -s "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/../../configs/.tmux.conf $HOME/.tmux.conf
