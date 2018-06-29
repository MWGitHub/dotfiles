# This may not be as safe as restarting the WSL service.
Stop-Process -Name "wslhost" -Force
Stop-Process -Name "bash" -Force
Stop-Process -Name "watchexec" -Force
