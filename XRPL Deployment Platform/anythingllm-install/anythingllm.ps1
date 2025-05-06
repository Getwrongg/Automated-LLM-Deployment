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

# Display current directory
Write-Host "Current directory: $PSScriptRoot"

# List all files and directories in the current directory
Write-Host "Listing all items in the current directory..."
Get-ChildItem -Path .

# Ensure Docker Desktop is running
Write-Host "Starting Docker Desktop..."
# Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Wait for Docker to initialize
# Start-Sleep -Seconds 10

# Path to docker-compose file is assumed to be in the current directory
$composeFilePath = "docker-compose.yml"

# Stop any existing container
Write-Host "Stopping existing AnythingLLM container..."
docker-compose -f $composeFilePath down

# Build and start the container
Write-Host "Building AnythingLLM container..."
docker-compose -f $composeFilePath build --no-cache

Write-Host "Starting AnythingLLM container..."
docker-compose -f $composeFilePath up -d

# Restart Docker and AnythingLLM
Write-Host "Restarting Docker service..."
wsl --shutdown
Start-Service docker

Write-Host "Restarting AnythingLLM container..."
docker-compose -f $composeFilePath down
docker-compose -f $composeFilePath up -d

# Wait for the container to start
Start-Sleep -Seconds 5

# Configure Windows Firewall
Write-Host "Configuring Windows Firewall rules..."
New-NetFirewallRule -DisplayName "Allow AnythingLLM" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3001
New-NetFirewallRule -DisplayName "Allow Docker Outbound" -Direction Outbound -Action Allow -Program "C:\Program Files\Docker\Docker\resources\bin\docker.exe"

# Test AnythingLLM API status
Write-Host "Checking AnythingLLM API status..."
$Response = Invoke-WebRequest -Uri "http://localhost:3001/api/status" -UseBasicParsing -ErrorAction SilentlyContinue

if ($Response.StatusCode -eq 200) {
    Write-Host "AnythingLLM is running successfully!"
} else {
    Write-Host "Failed to reach AnythingLLM. Check logs: `n docker logs anythingllm --tail 50"
}
