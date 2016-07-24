#!/usr/bin/env bash

cd ~
apt-get update
apt-get install git-core
git clone https://github.com/MWGitHub/dotfiles.git

# From https://github.com/webcoyote/dotfiles configure.sh
# Copy all dotfiles into home
function link_home() {
  for file in $1/?*; do
    if [[ -d $file ]]; then
      mkdir -p $2/`basename $file`
      link_home $file $2/`basename $file`
    else
      echo linking $file '=>' $2/`basename $file`
      ln -s -f $file $2/`basename $file`
    fi
  done
}
shopt -s dotglob
link_home dotfiles/home $HOME
shopt -u dotglob