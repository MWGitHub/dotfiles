#!/usr/bin/env bash

cd ~
apt-get update
apt-get install git-core
git clone https://github.com/MWGitHub/dotfiles.git

# Copy all dotfiles into home
function link_home() {
  for file in dotfiles/home/?*; do
    if [[ -d $file ]]; then
      mkdir -p $2/`basename $file`
      link_home $file $2/`basename $file`
    else
      ln -s -f $file $2/`basename $file`
    fi
  done
}
link_home