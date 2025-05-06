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

# Define the keyword for targeted Docker resources
$keyword = "anythingllm"

# Find and stop all running containers related to the keyword
Write-Host "Stopping all running Docker containers related to '$keyword'..."
docker ps -aqf "name=$keyword" | ForEach-Object { docker stop $_ }

# Find and remove all containers related to the keyword
Write-Host "Removing all Docker containers related to '$keyword'..."
docker ps -aqf "name=$keyword" | ForEach-Object { docker rm $_ }

# Find and remove all images related to the keyword
Write-Host "Removing all Docker images related to '$keyword'..."
docker images -aqf "reference=$keyword" | ForEach-Object { docker rmi $_ }

# Find and remove all volumes related to the keyword
Write-Host "Removing all Docker volumes related to '$keyword'..."
docker volume ls -qf "name=$keyword" | ForEach-Object { docker volume rm $_ }

# Find and remove all networks related to the keyword
Write-Host "Removing all Docker networks related to '$keyword'..."
docker network ls -qf "name=$keyword" | ForEach-Object { docker network rm $_ }

Write-Host "All Docker resources related to '$keyword' have been completely removed."
