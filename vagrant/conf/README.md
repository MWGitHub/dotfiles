### conf

Place sensitive files to copy in here to be used by the vm.

#### Current support
* copies `.ssh/id_rsa` to `~/.ssh/id_rsa`
* runs `setenv.sh` (environment variables and user settings)
* copies `userexec.sh` to `~/userexec.sh` (commands to run as the user)
