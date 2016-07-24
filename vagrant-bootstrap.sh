#!/usr/bin/env bash

cd ~
apt-get update
apt-get install git-core
git clone https://github.com/MWGitHub/dotfiles.git

# Copy all dotfiles into home
find dotfiles/home -exec ln -s . {} \;