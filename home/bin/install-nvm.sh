#!/usr/bin/env bash

curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.4/install.sh | bash

zsh

nvm install stable
nvm alias default stable
