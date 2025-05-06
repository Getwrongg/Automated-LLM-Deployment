# Elevate script to run as Administrator
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$AdminRole = [System.Security.Principal.WindowsPrincipal]::new($CurrentUser)
if (-not $AdminRole.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Restarting script with Administrator privileges..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Set PowerShell to stop on all errors
$ErrorActionPreference = 'Stop'

# Display current Docker containers
Write-Host "Listing current Docker containers..."
docker ps -a

# Stopping all running Docker containers
Write-Host "Stopping all running Docker containers..."
docker stop $(docker ps -aq)

# Removing all Docker containers
Write-Host "Removing all Docker containers..."
docker rm $(docker ps -aq)

# Removing all Docker images
Write-Host "Removing all Docker images..."
docker rmi $(docker images -aq)

# Removing all Docker volumes
Write-Host "Removing all Docker volumes..."
docker volume rm $(docker volume ls -q)

# Removing all Docker networks (excluding default networks)
Write-Host "Removing all custom Docker networks..."
docker network prune -f

Write-Host "All Docker containers, images, volumes, and networks have been completely removed."
