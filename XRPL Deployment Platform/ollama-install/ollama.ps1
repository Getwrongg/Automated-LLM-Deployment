# Elevate script to run as Administrator
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$AdminRole = [System.Security.Principal.WindowsPrincipal]::new($CurrentUser)
if (-not $AdminRole.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Restarting script with Administrator privileges..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Set working directory to script location
Set-Location "$PSScriptRoot"

# Check if Docker is installed
if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Host "Docker is not installed. Please install Docker before running this script."
    exit
}

# Ensure Docker Desktop is running
Write-Host "Starting Docker Desktop..."
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Wait for Docker to initialize
Start-Sleep -Seconds 10

# Pull the required images
Write-Host "Pulling the latest Ollama image..."
docker pull ollama/ollama:latest

# Check if Ollama is already running via docker-compose
$RunningContainer = docker ps --filter "name=ollama" --format "{{.Names}}"
if ($RunningContainer -eq "ollama") {
    Write-Host "Ollama container is already running. Stopping it now..."
    docker-compose down
}

# Start Ollama using docker-compose.yml
Write-Host "Starting the Ollama container using docker-compose..."
docker-compose up -d --build

# Configure Windows Firewall
Write-Host "Configuring Windows Firewall rules..."
New-NetFirewallRule -DisplayName "Allow Ollama" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 11434 -Force
New-NetFirewallRule -DisplayName "Allow Docker Outbound" -Direction Outbound -Action Allow -Program "C:\Program Files\Docker\Docker\resources\bin\docker.exe" -Force

# Restart Docker service to apply changes
Write-Host "Restarting Docker service..."
wsl --shutdown
Start-Service docker

# Final check to see if the container is running properly
Start-Sleep -Seconds 5
$Response = Invoke-WebRequest -Uri "http://localhost:11434/api/status" -UseBasicParsing -ErrorAction SilentlyContinue
if ($Response.StatusCode -eq 200) {
    Write-Host "Everything is up and running successfully!"
} else {
    Write-Host "There may be an issue. Please check the container logs."
}
