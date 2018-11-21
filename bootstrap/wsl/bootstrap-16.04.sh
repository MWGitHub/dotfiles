#!/usr/bin/env bash

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
# have public key be 644
# have private key be 600

BOOTSTRAP_DIR="$(mktemp -d "${HOME}"/.bootstrap.XXXXXX)"
LOCAL_DIR="$HOME/.local"

########################################
# Check if an archive is already in sources
# Globals:
#   None
# Arguments:
#   grep_pattern
# Returns:
#   0 if it exists
#   1 if it does not exist
########################################
is_in_sources() {
  local in_sources=
  in_sources=$(cat /etc/apt/sources.list /etc/apt/sources.list.d/*.list | grep "$1")
  if [ -n "$in_sources" ]; then
    return 0
  else
    return 1
  fi
}

########################################
# Check if a binary or script is already installed
# Globals:
#   None
# Arguments:
#   command
#   [required_version]
#   [version_retrieval]
# Returns:
#   0 if it exists
#   1 if it does not exist
########################################
is_already_installed() {
  check_version() {
    local command="$1"
    local required_version="$2"
    local version_retrieval=${3:-'--version'}
    local version=
    if [ -n "${required_version}" ]; then
      version="$("${command}" "${version_retrieval}" | grep "${required_version}")"
      if [ -z "${version}" ]; then
        return 1
      fi
    fi

    return 0
  }

  local path=
  path="$(command -v "$1")"
  check_version "$1" "$2" "$3"
  version_matches="$?"
  if [ -n "$path" ] && [ "$version_matches" -eq 0 ]; then
    return 0
  else
    return 1
  fi

  return 0
}

# Create the structure for common directories
create_directory_structure() {
  mkdir -p "$HOME/.local/bin" \
   "$HOME/tools" \
   "$HOME/scripts" \
   "$HOME/projects" \
   "$HOME/builds"
}

# This is assuming keychains are set up
install_common() {
  # add some additional sources for common programs
  is_in_sources git-core
  if [ $? -eq 1 ]; then
    sudo add-apt-repository -y ppa:git-core/ppa
  fi

  sudo apt update -y
  sudo apt upgrade -y
  # Required software for building other dependencies
  # or retrieving sources
  sudo apt install -y \
    gcc clang gdb build-essential make automake llvm \
    openssh-server ca-certificates \
    software-properties-common apt-transport-https \
    unzip p7zip-full tar \
    libpng-dev zlib1g-dev libssl-dev libbz2-dev \
    libreadline-dev libsqlite3-dev libncurses5-dev \
    libncursesw5-dev xz-utils libgit2-24 libgit2-dev \
    libutf8proc-dev libutf8proc1 \
  # Git addons
  git lfs --version &> /dev/null
  if [ $? -eq 1 ]; then
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
    sudo apt-get install git-lfs -y
    git lfs install
  fi
  # Languages
  sudo apt install -y python3-pip python-dev python3-dev \
    lua5.3 liblua5.3-0 liblua5.3-dev \
    tk-dev tcl tcl-dev default-jdk \
    ruby ruby-all-dev
  # tmux 2.7 requirements
  sudo apt install pkg-config libevent-dev \
    libncurses5-dev ncurses-dev -y
  # Standard and nice software to have
  sudo apt install htop jq tree curl wget oathtool -y
  sudo apt auto-remove -y
  sudo apt install shellcheck -y

  # Install CMake
  local cmake_version="3.12.2"
  is_already_installed "cmake" "${cmake_version}"
  if [ "$?" -eq 1 ]; then
    local cmake_source=
    cmake_source="$(mktemp -d "${BOOTSTRAP_DIR}"/cmake.XXX)"
    cd "${cmake_source}"
    wget "https://cmake.org/files/v${cmake_version%.*}/cmake-${cmake_version}.tar.gz"
    tar xzf "cmake-${cmake_version}.tar.gz"
    rm "cmake-${cmake_version}.tar.gz"
    cd "cmake-${cmake_version}"
    ./bootstrap "--prefix=${LOCAL_DIR}" && make && make install
  fi
}

# This sets up an ssh server and allows for external tools to connect
# Make sure to allow password authentication if connecting with CLion in /etc/ssh/sshd_config
# If on an older version of Ubuntu, set UsePrivilegeSeparate to no
# Switch port to 2222
install_remote() {
  sudo apt remove -y --purge openssh-server
  sudo apt install -y openssh-server
  # sudo systemctl enable ssh # at the moment WSL does not run systemd
  sudo apt auto-remove -y
}

install_docker_wsl() {
  is_in_sources "docker"
  if [ $? -eq 1 ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88

    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  fi

  sudo apt update
  sudo apt install -y docker-ce
  sudo usermod -aG docker "$USER"

  # Install Docker Compose.
  local has_compose=
  has_compose=$(command -v docker-compose)
  if [ -z "$has_compose" ]; then
    sudo curl -L https://github.com/docker/compose/releases/download/"${DOCKER_COMPOSE_VERSION}"/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose &&
    sudo chmod +x /usr/local/bin/docker-compose
  fi
}

link_configs() {
  repo=multibootstrap

  projects="$HOME/projects"
  cd "$projects"
  if [ -d $repo ]; then
    cd $repo
    git pull
  else
    # Use https first before git in case ssh is not set up yet
    git clone https://gitlab.com/autolife/development/$repo.git
    # Reset dotfiles origins
    cd "$HOME/projects/$repo"
    git remote set-url origin git@gitlab.com:autolife/development/$repo.git
  fi

  # Link config files
  configs="$HOME/projects/$repo/configs"
  ln -sf "$configs/.bashrc" "$HOME/.bashrc"
  if [ ! -h "$HOME/.bashconf" ]; then
    ln -sf "$configs/.bashconf" "$HOME/.bashconf"
  fi
  if [ ! -e "$HOME/.bashconf/.bashrc.local.precommon" ]; then
    touch "$HOME/.bashconf/.bashrc.local.precommon"
  fi
  if [ ! -e "$HOME/.bashconf/.bashrc.local" ]; then
    touch "$HOME/.bashconf/.bashrc.local"
  fi

  ln -srf $(ls "$configs"/.git*) ~

  ln -srf $(ls "$configs"/.tmux*) ~

  if [ ! -h "$HOME/.vim" ]; then
    ln -sf "$configs/.vim" "$HOME/.vim"
  fi
  if [ ! -e "$HOME/.vim/.vimrc.local" ]; then
    touch "$HOME/.vim/.vimrc.local"
  fi
  ln -srf $(ls "$configs"/.vimrc*) ~

  if [ ! -h "$HOME/.config" ]; then
    ln -sf "$configs/.config" "$HOME/.config"
  fi

  # Misc one off files
  ln -sf "$configs/.inputrc" "$HOME/.inputrc"

  source "$HOME/.bashrc"
}

install_languages() {
  # Install pyenv
  local has_pyenv=
  has_pyenv=$(command -v pyenv)
  if [ -z "$has_pyenv" ]; then
    curl -Lq https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
  fi

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

  # Install nvm
  if [ ! -d "$HOME/.nvm" ]; then
    git clone https://github.com/creationix/nvm.git "$HOME/.nvm"
    cd "$HOME/.nvm"
    git checkout v0.33.11
  fi

  # Rust
  has_rust=$(command -v rustc)
  if [ -z "$has_rust" ]; then
    curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path
    ~/.cargo/bin/cargo install racer
  else
    rustup update
  fi

  # Go
  has_golang=$(command -v go)
  if [ -z "$has_golang" ]; then
    local go_temp="$(mktemp -d "${BOOTSTRAP_DIR}/go.XXX")"
    cd "$go_temp"
    wget https://dl.google.com/go/go1.11.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.11.linux-amd64.tar.gz
    if [ ! -d "$GOPATH/.go/code" ]; then
      mkdir -p "$HOME/.go/code"
    fi
  fi
}

set_wsl_configs() {
  local is_windows=
  is_windows="$(uname -a | grep Microsoft)"
  if [ -z "${is_windows}" ]; then
    return 0
  fi

  # WSL specific variables
  local appended_ssh=
  appended_ssh="$(grep START_SSH "${HOME}/.bashconf/.bashrc.local.precommon")"
  if [ -z "${appended_ssh}" ]; then
    echo export START_SSH="true" >> "$HOME/.bashconf/.bashrc.local.precommon"
  fi
}

install_tools() {
  cd "$HOME/tools"

  # Install nginx
  sudo apt-get install -y nginx

  # Install terraform
  if [ ! -f "$HOME/tools/terraform" ]; then
    wget https://releases.hashicorp.com/terraform/0.11.10/terraform_0.11.10_linux_amd64.zip
    unzip terraform*.zip
    rm terraform*.zip
  fi

  # Install vault
  if [ ! -f "$HOME/tools/vault" ]; then
    wget https://releases.hashicorp.com/vault/0.11.1/vault_0.11.1_linux_amd64.zip
    unzip vault*.zip
    rm vault*.zip
  fi

  # Install ansible
  is_in_sources "ansible"
  if [ $? -eq 1 ]; then
    sudo apt-add-repository ppa:ansible/ansible -y
  fi
  sudo apt-get update -y
  sudo apt-get install ansible

  # Install aws
  pip install awscli --upgrade --user

  # Install Google Cloud SDK
  is_in_sources "cloud.google.com"
  if [ $? -eq 1 ]; then
    cloud_sdk_repo="cloud-sdk-$(lsb_release -c -s)"
    echo "deb http://packages.cloud.google.com/apt $cloud_sdk_repo main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  fi
  sudo apt-get update -y && sudo apt-get install google-cloud-sdk -y

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

  # Build and make vim
  has_vim_7=$(vim --version | grep 7.4)
  if [ -n "$has_vim_7" ]; then
    sudo apt remove vim -y
    cd "$HOME/builds"
    git clone https://github.com/vim/vim.git
    cd vim
    ./configure --enable-luainterp=yes --with-lua-prefix=/usr/bin/lua5.3 \
      --enable-perlinterp=yes --enable-pythoninterp=yes \ 
      --with-python-command=python2 --enable-python3interp=yes \
      --with-python3-command=python --enable-tclinterp=yes \
      --enable-rubyinterp=yes --enable-cscope --enable-terminal \
      --enable-multibyte --enable-gui=no --disable-sysmouse \
      --with-compiledby=MW --with-tclsh=/usr/bin/tclsh --with-tlib=ncurses \
      && make
      sudo make install
  fi

  # Install Bats
  local has_bats=
  has_bats=$(command -v bats)
  if [ -z "$has_bats" ]; then
    cd "$HOME/builds"
    git clone https://github.com/bats-core/bats-core.git
    cd bats-core
    ./install.sh "$HOME/.local"
  fi

  # Install Kubernetes
  sudo apt-get update
  sudo apt-get install -y apt-transport-https curl
  is_in_sources "kubernetes"
  if [ $? -eq 1 ]; then
    sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
  fi
  sudo apt-get update
  sudo apt-get install -y kubelet kubeadm kubectl
  sudo apt-mark hold kubelet kubeadm kubectl

  # Install geth
  is_in_sources "ethereum"
  if [ $? -eq 1 ]; then
    sudo add-apt-repository -y ppa:ethereum/ethereum
    sudo apt-get update
  fi
  sudo apt-get install -y ethereum
  sudo apt-get install -y solc

#  # Install aleth
#  is_already_installed "aleth"
#  if [ $? -eq 1 ]; then
#    local aleth_build=
#    aleth_build="$(mktemp -d "${BOOTSTRAP_DIR}/aleth")"
#    cd "${aleth_build}"
#    git clone --recursive https://github.com/ethereum/aleth.git
#    cd "aleth"
#    sudo apt-get install libleveldb-dev -y
#    mkdir build
#    cd build
#    cmake ..
#    cmake --build . 
#  fi
}

install_scripts() {
  cd "$HOME/projects"

  if [ ! -d "$HOME/projects/scripts" ]; then
    git clone https://gitlab.com/mwguy/scripts.git
  fi
  
  cd scripts
  git pull origin master
}

install_plugins() {
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

cleanup() {
  rm -rf "${BOOTSTRAP_DIR}"

  unset BOOTSTRAP_DIR
  unset LOCAL_DIR

  trap '' EXIT
}

main() {
  trap cleanup EXIT
  echo "Beginning bootstrap for WSL"

  starting_dir=$PWD

  create_directory_structure
  install_common
  install_remote
  install_docker_wsl
  link_configs
  install_languages
  set_wsl_configs
  install_tools
  install_scripts
  install_plugins

  cd "$starting_dir"

  echo "Bootstrapping completed"
  echo "Be sure to run :PlugInstall in vim"
  echo "Be sure to hit ctrl+b-I to install tmux plugins"

  source "${HOME}/.bashrc"
}

main
