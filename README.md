# dotfiles
My configuration and setup files.

## Usage

This repository can be used in multiple ways.

### WSL

1. Install WSL Ubuntu
1. Follow the instructions in the following file before running it: https://github.com/MWGitHub/dotfiles/blob/master/bootstrap/wsl/bootstrap.sh
1. Close the Ubuntu session
1. Inside windows command run `ubuntu config --default-user <username>`
1. Open up the Ubuntu session, it should now default to the non-root usename
1. run `wget -O - https://github.com/MWGitHub/dotfiles/blob/master/bootstrap/wsl/bootstrap.sh | bash

#### Manual installation

1. Clone the repository by running `git clone https://github.com/MWGitHub/dotfiles.git`
2. Copy files and directories you want to use from `dotfiles/home` into your home directory while keeping the relative paths.
3. Set scripts to be executable and run the scripts for programs you wish to install.

#### Automatic installation

1. Clone the repository by running `git clone https://github.com/MWGitHub/dotfiles.git`.
2. Copy the `dotfiles` folder into your home directory.
3. Set bootstrap.sh to executable and run the script with `./dotfiles/bootstrap.sh`.

#### Setting up a machine with Vagrant

1. Clone the repository by running `git clone https://github.com/MWGitHub/dotfiles.git`
2. Run `vagrant up`.
3. SSH into the machine with the generated key.

