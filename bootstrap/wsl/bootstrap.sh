#!/usr/bin/env bash

echo "Beginning bootstrap for WSL"

# Create a user
# adduser foo
# usermod -aG sudo foo
# log in as user
# cd ~
# mkdir .ssh
# chmod 700 .ssh

# Setting up keychain
# sudo apt update
# sudo apt install keychain
# copy over or create a new ssh key pair
# this assumes keychain uses id_rsa to access github

# This is assuming keychains are set up
sudo apt update -y
sudo apt upgrade -y
sudo apt install openssh-server python3-pip -y

# This sets up an ssh server and allows for external tools to connect
# Make sure to allow password authentication if connecting with CLion in /etc/ssh/sshd_config
sudo apt remove -y --purge openssh-server
sudo apt install -y openssh-server
# sudo systemctl enable ssh # at the moment WSL does not run systemd
sudo apt install cmake gcc clang gdb build-essential -y

sudo apt auto-remove -y

mkdir -p "$HOME/tools" "$HOME/scripts" "$HOME/projects"

projects="$HOME/projects"
cd "$projects"
if [ -d dotfiles ]; then
	cd dotfiles
	git pull
else
	git clone https://github.com/MWGitHub/dotfiles.git 
fi

# Link config files
configs="$HOME"/projects/dotfiles/configs
ln -srf $(ls "$configs"/.bash*) ~
ln -srf $(ls "$configs"/.git*) ~
ln -srf $(ls "$configs"/.tmux*) ~

# Install dependencies the configs use
wget https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy -O "$HOME"/scripts/diff-so-fancy -q
chmod +x "$HOME/scripts/diff-so-fancy"

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Install python
curl -Lq https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
pip3 install pipenv

# Install node
if [ ! -d "$HOME/.nvm" ]; then
	git clone https://github.com/creationix/nvm.git "$HOME/.nvm"
	cd "$HOME/.nvm"
	git checkout v0.33.11
fi

# Reset dotfiles origins
cd "$HOME/projects/dotfiles"
git remote set-url origin git@github.com:MWGitHub/dotfiles.git

exec bash

echo "Bootstrapping completed"

