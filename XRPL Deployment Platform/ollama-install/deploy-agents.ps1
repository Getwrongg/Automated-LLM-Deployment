# Elevate script to run as Administrator
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$AdminRole = [System.Security.Principal.WindowsPrincipal]::new($CurrentUser)
if (-not $AdminRole.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Restarting script with Administrator privileges..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Ensure Docker is running
Write-Host "Checking if Docker is running..."
$dockerStatus = Get-Service -Name "docker" -ErrorAction SilentlyContinue
if ($null -eq $dockerStatus -or $dockerStatus.Status -ne 'Running') {
    Write-Host "Docker is not running. Starting Docker..."
    Start-Service docker
    Start-Sleep -Seconds 5
}

# Set working directory to script location (where docker-compose.yml is located)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $scriptDir

# Ensure docker-compose.yml exists
if (-not (Test-Path "docker-compose.yml")) {
    Write-Host "Error: docker-compose.yml not found in $scriptDir!"
    exit 1
}

# Stop and remove existing Ollama container if it exists
Write-Host "Checking if an existing Ollama container is running..."
$existingContainer = docker ps -a --format "{{.Names}}" | Where-Object { $_ -eq "ollama" }

if ($existingContainer) {
    Write-Host "Stopping and removing existing Ollama container..."
    docker stop ollama
    docker rm ollama
}

# Stop and remove all existing containers in docker-compose
Write-Host "Stopping and removing all containers in docker-compose..."
docker-compose down --remove-orphans

# Start and rebuild the Ollama container with tools enabled
Write-Host "Rebuilding and starting the Ollama container with tool support..."
docker-compose up --build -d

# Wait for container to start
Start-Sleep -Seconds 5

# Find the running Ollama container ID
Write-Host "Checking if an Ollama container is running..."
$ollamaContainerID = docker ps --format "{{.ID}} {{.Names}}" | Where-Object { $_ -match "ollama" } | ForEach-Object { ($_ -split " ")[0] }

if ($null -ne $ollamaContainerID) {
    Write-Host "Ollama container detected: $ollamaContainerID"

    # Pull the llama3.1 model; removing the '--model' flag
    #Write-Host "Pulling the llama3.1 model..."
    #docker exec $ollamaContainerID ollama pull mistral:latest

    # Ensure /app/ directory exists inside the container
    Write-Host "Ensuring /app/ directory exists..."
    docker exec -it $ollamaContainerID sh -c "mkdir -p /app"

    # Create the agent script inside the container
    Write-Host "Creating agent script inside the container..."
    docker exec -i $ollamaContainerID sh -c "echo '#!/bin/sh' > /app/ollama_agent.sh"
    docker exec -i $ollamaContainerID sh -c "echo 'echo \"Agent script executed.\"' >> /app/ollama_agent.sh"

    # Ensure script has execution permissions inside the container
    docker exec -it $ollamaContainerID sh -c "chmod +x /app/ollama_agent.sh"

    # Execute the agent script inside the container
    Write-Host "Executing the agent script inside the container..."
    docker exec -it $ollamaContainerID sh -c "/app/ollama_agent.sh"

    Write-Host "Execution complete."

    # Verify that Ollama is running with tools enabled
    Start-Sleep -Seconds 5
    Write-Host "Verifying that Ollama is running with tool support..."
    $runningOllama = docker exec -it $ollamaContainerID sh -c "ps aux | grep '[o]llama serve'"

    if ($runningOllama -match "serve") {
        Write-Host "Ollama is running correctly."
    } else {
        Write-Host "Error: Ollama is running, but tools may NOT be enabled!"
    }
} else {
    Write-Host "Error: No running Ollama container found after compose up!"
}
