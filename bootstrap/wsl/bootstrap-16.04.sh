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
  # Required software for building other dependencies
	sudo apt install openssh-server python3-pip cmake gcc \
		 clang gdb build-essential unzip p7zip-full tar \
		 libpng-dev zlib1g-dev make libssl-dev libbz2-dev \
		 libreadline-dev libsqlite3-dev llvm libncurses5-dev \
		 libncursesw5-dev xz-utils tk-dev libgit2-24 libgit2-dev \
		 apt-transport-https ca-certificates \
     python-dev python3-dev libutf8proc-dev libutf8proc1 \
		 software-properties-common -y
  # tmux 2.7 requirements
  sudo apt install automake build-essential pkg-config libevent-dev \
    libncurses5-dev ncurses-dev -y
  # Standard and nice software to have
  sudo apt install htop jq tree curl wget -y
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

function install_docker_wsl() {
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo apt-key fingerprint 0EBFCD88

	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

	sudo apt update
	sudo apt install -y docker-ce
	sudo usermod -aG docker $USER

	# Install Docker Compose.
	sudo curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose &&
	sudo chmod +x /usr/local/bin/docker-compose
}

function link_configs() {
	mkdir -p "$HOME/tools" "$HOME/scripts" "$HOME/projects" "$HOME/builds"

	projects="$HOME/projects"
	cd "$projects"
	if [ -d dotfiles ]; then
		cd dotfiles
		git pull
	else
    # Use https first before git in case ssh is not set up yet
		git clone https://github.com/MWGitHub/dotfiles.git 

    # Reset dotfiles origins
    cd "$HOME/projects/dotfiles"
    git remote set-url origin git@github.com:MWGitHub/dotfiles.git
	fi

	# Link config files
	configs="$HOME/projects/dotfiles/configs"
  ln -sf "$configs/.bashrc" "$HOME/.bashrc"
  if [ ! -h "$HOME/.bashconf" ]; then
    ln -sf "$configs/.bashconf" "$HOME/.bashconf"
  fi

	ln -srf $(ls "$configs"/.git*) ~

	ln -srf $(ls "$configs"/.tmux*) ~

  if [ ! -h "$HOME/.vim" ]; then
  	ln -sf "$configs/.vim" "$HOME/.vim"
  fi
	ln -srf $(ls "$configs"/.vimrc*) ~

  if [ ! -h "$HOME/.config" ]; then
  	ln -sf "$configs/.config" "$HOME/.config"
  fi

  source "$HOME/.bashrc"
}

function install_language_managers() {
	# Install python
	curl -Lq https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash

  sudo apt install socat -y

  has_pyenv2=$(pyenv versions | grep 2.7.15)
  if [ -z "$has_pyenv2" ]; then
    pyenv install 2.7.15
  fi
  pyenv global 2.7.15
  pip install --upgrade pip
  pip install --user pipenv
  # Powerlines optional dependencies
  pip install --user psutil
  pip install --user python-hglib
  pip install --user pygit2==0.24.2
  pip install --user pyuv

  has_pyenv3=$(pyenv versions | grep 3.6.5)
  if [ -z "$has_pyenv3" ]; then
    pyenv install 3.6.5
  fi
  pyenv global 3.6.5

  pip install --upgrade pip
  pip install --user pipenv
  # Powerlines optional dependencies
  pip install --user psutil
  pip install --user python-hglib
  pip install --user pygit2==0.24.2
  pip install --user pyuv

	# Install node
	if [ ! -d "$HOME/.nvm" ]; then
		git clone https://github.com/creationix/nvm.git "$HOME/.nvm"
		cd "$HOME/.nvm"
		git checkout v0.33.11
	fi


  # Rust
  has_rust=$(which rustc)
  if [ -z "$has_rust" ]; then
    curl https://sh.rustup.rs -sSf | sh
    ~/.cargo/bin/cargo install racer
  else
    rustup update
  fi
}

function install_plugins() {
	# Install dependencies the configs use
	wget https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy -O "$HOME"/scripts/diff-so-fancy -q
	chmod +x "$HOME/scripts/diff-so-fancy"

	# tmux plugin manager
	if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
		git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	fi

	# Install powerlines, make sure there's a support font
	# https://github.com/powerline/fonts
	pip install --user powerline-status
}
function set_wsl_configs() {
	# WSL specific variables
	appended_ssh=$(cat "$HOME/.bashrc.local" | grep START_SSH)
	if [ -z "$appended_ssh" ]; then
		echo export START_SSH="true" >> "$HOME/.bashrc.local"
	fi
}

function install_tools() {
	cd "$HOME/tools"

	# Install terraform
	if [ ! -f "$HOME/tools/terraform" ]; then
		wget https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip
		unzip terraform*.zip
		rm terraform*.zip
	fi

	# Install vault
	if [ ! -f "$HOME/tools/vault" ]; then
		wget https://releases.hashicorp.com/vault/0.10.1/vault_0.10.1_linux_amd64.zip
		unzip vault*.zip
		rm vault*.zip
	fi

	sudo apt-add-repository ppa:ansible/ansible -y
	sudo apt-get update -y
	sudo apt-get install ansible

	# Install aws
	pip install awscli --upgrade --user

  # Build and make tmux
  tmux_version=$(tmux -V | grep 2.7)
  if [ -z "$tmux_version" ]; then
    sudo apt remove tmux -y
    cd "$HOME/builds"
    git clone https://github.com/tmux/tmux.git
    cd tmux && git checkout 2.7
    sh autogen.sh
    ./configure --enable-utf8proc && make
    sudo make install
  fi
}


starting_dir=$PWD

install_common
install_remote
install_docker_wsl
link_configs
install_language_managers
install_plugins
set_wsl_configs
install_tools

cd "$starting_dir"

echo "Bootstrapping completed"

exec bash
