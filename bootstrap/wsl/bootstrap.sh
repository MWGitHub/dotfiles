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
function install_common() {
	sudo apt update -y
	sudo apt upgrade -y
	sudo apt install openssh-server python3-pip cmake gcc \
			 clang gdb build-essential unzip p7zip-full -y
	sudo apt auto-remove -y
}

# This sets up an ssh server and allows for external tools to connect
# Make sure to allow password authentication if connecting with CLion in /etc/ssh/sshd_config
# If on an older version of Ubuntu, set UsePrivilegeSeparate to no
# Switch port to 2222
function install_remote() {
	sudo apt remove -y --purge openssh-server
	sudo apt install -y openssh-server
	# sudo systemctl enable ssh # at the moment WSL does not run systemd
	sudo apt auto-remove -y
}

function link_configs() {
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
}

function install_plugins() {
	# Install dependencies the configs use
	wget https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy -O "$HOME"/scripts/diff-so-fancy -q
	chmod +x "$HOME/scripts/diff-so-fancy"

	# tmux plugin manager
	if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
		git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	fi
}

function install_language_managers() {
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
}

function set_wsl_configs() {
	# WSL specific variables
	appended_ssh=$(cat "$HOME/.bashrc.local" | grep START_SSH)
	if [ -z "$appended_ssh" ]; then
		echo export START_SSH="true" >> "$HOME/.bashrc.local"
	fi
}

function install_tools() {
	if [ ! -f "$HOME/tools/terraform" ]; then
		echo "Installing terraform"
	fi
}


install_common
install_remote
link_configs
install_language_managers
set_wsl_configs
install_tools

exec bash

echo "Bootstrapping completed"

