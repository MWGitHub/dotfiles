#/usr/bin/env bash

sudo apt-get -y install zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Change the oh my zsh default theme.
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="3den"/g' ~/.zshrc

zsh
