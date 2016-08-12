#!/usr/bin/env bash

cd ~
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install git-core
git clone https://github.com/MWGitHub/dotfiles.git

# Run bootstrap
chmod +x ./dotfiles/bootstrap.sh
./dotfiles/bootstrap.sh

# Set up keys
cp /vagrant/conf/.ssh/id_rsa ~/.ssh/id_rsa
chmod 700 ~/.ssh/id_rsa

# Set environment
/vagrant/conf/setenv.sh

# Put user run script in home
cp /vagrant/userexec.sh ~/userexec.sh
