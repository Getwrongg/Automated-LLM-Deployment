# Elevate script to run as Administrator if needed
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$AdminRole = [System.Security.Principal.WindowsPrincipal]::new($CurrentUser)
if (-not $AdminRole.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Restarting script with Administrator privileges..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# ---------------------------
#   Configuration Variables
# ---------------------------
$OLLAMA_API_PORT = 3011
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$OLLAMA_API_PACKAGE = Join-Path $SCRIPT_DIR "Ollama.zip"
$DEPLOYMENT_PATH = $SCRIPT_DIR

# ---------------------------
#   Check Docker Availability
# ---------------------------
Write-Host "Checking if Docker CLI is installed..."
try {
    docker --version | Out-Null
} catch {
    Write-Host "Docker does not appear to be installed or is not in PATH."
    Pause
    exit 1
}
Write-Host "Docker is installed. Proceeding..."

# ---------------------------
#   Confirm the ZIP exists
# ---------------------------
Write-Host "Checking for Ollama API ZIP package..."
if (-not (Test-Path $OLLAMA_API_PACKAGE)) {
    Write-Host "Error: Ollama API zip package not found at $OLLAMA_API_PACKAGE"
    Pause
    exit 1
}
Write-Host "Found package: $OLLAMA_API_PACKAGE"

# ---------------------------
#   Clean Up Existing Container
# ---------------------------
Write-Host "Checking if an existing Ollama API container is running..."
$existingContainer = docker ps -a --format "{{.Names}}" | Where-Object { $_ -eq "ollama-api" }

if ($existingContainer) {
    Write-Host "Stopping and removing existing Ollama API container..."
    docker stop ollama-api | Out-Null
    docker rm ollama-api   | Out-Null
}

# ---------------------------
#   Build New Docker Image
# ---------------------------
Write-Host "Building the Ollama API container..."
docker build -t ollama-api -f "$DEPLOYMENT_PATH\Dockerfile" "$DEPLOYMENT_PATH"

# Verify that the image was built
if (-not (docker images -q ollama-api)) {
    Write-Host "Error: Ollama API Docker image was not built."
    Pause
    exit 1
}

# ---------------------------
#   Run the Ollama API Container
# ---------------------------
Write-Host "Starting the Ollama API container on port $OLLAMA_API_PORT..."
docker run -d --name ollama-api -p ${OLLAMA_API_PORT}:${OLLAMA_API_PORT} ollama-api

# Wait a few seconds for the container to start
Start-Sleep -Seconds 5

# ---------------------------
#   Health Check
# ---------------------------
Write-Host "Checking if Ollama API container is running..."
$containerID = docker ps --format "{{.ID}} {{.Names}}" |
    Where-Object { $_ -match "ollama-api" } |
    ForEach-Object { ($_ -split " ")[0] }

if ($null -ne $containerID) {
    Write-Host "Ollama API container detected: $containerID"

    # Verify that the API is responding
    Start-Sleep -Seconds 5
    Write-Host "Verifying that Ollama API is accessible on http://localhost:$OLLAMA_API_PORT/is-alive ..."
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$OLLAMA_API_PORT/is-alive" -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "Ollama API is running correctly on port $OLLAMA_API_PORT."
        } else {
            Write-Host "Warning: Ollama API container is running but returned an unexpected response."
        }
    } catch {
        Write-Host "Error: Ollama API did not respond on port $OLLAMA_API_PORT."
    }
} else {
    Write-Host "Error: No running Ollama API container found."
}

# ---------------------------
#   Open Firewall Port 3011
# ---------------------------
Write-Host "`nChecking if firewall rule exists for port $OLLAMA_API_PORT..."
$ruleName = "Ollama API Port $OLLAMA_API_PORT"

$existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

if (-not $existingRule) {
    Write-Host "Firewall rule not found. Creating rule to allow inbound TCP on port $OLLAMA_API_PORT..."
    New-NetFirewallRule -DisplayName $ruleName `
                        -Direction Inbound `
                        -Action Allow `
                        -Protocol TCP `
                        -LocalPort $OLLAMA_API_PORT `
                        -Profile Any
    Write-Host "Firewall rule created."
} else {
    Write-Host "Firewall rule for port $OLLAMA_API_PORT already exists."
}

Pause
