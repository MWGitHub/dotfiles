#!/usr/bin/env bash

cd ~
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install git-core
git clone https://github.com/MWGitHub/dotfiles.git

# Run bootstrap
chmod +x ./dotfiles/bootstrap.sh
./dotfiles/bootstrap.sh vagrant
