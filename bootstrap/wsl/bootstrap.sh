#!/usr/bin/env bash

echo "Beginning bootstrap for WSL"

# This is assuming keychains are set up
sudo apt update
sudo apt upgrade
sudo apt install openssh-server
sudo apt auto-remove

mkdir -p "$HOME"/tools "$HOME"/scripts "$HOME"/projects

projects="$HOME/projects"
cd "$projects"
if [ -d dotfiles ]; then
	cd dotfiles
	git pull
else
	git clone https://github.com/MWGitHub/dotfiles.git
fi

configs="$HOME"/projects/dotfiles/configs

ln -srf $(ls "$configs"/.bash*) ~
ln -srf $(ls "$configs"/.git*) ~
ln -srf $(ls "$configs"/.tmux*) ~

wget https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy -P "$HOME"/scripts -q

echo "Bootstrapping completed"
