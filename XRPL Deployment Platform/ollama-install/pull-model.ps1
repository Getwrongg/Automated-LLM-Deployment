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

# Define the model to use
#$Model = "deepseek-r1"   # Default: DeepSeek
$Model = "llama3.2"    # Uncomment for Llama3.2
#$Model = "mistral:latest"  # Uncomment for Mistral-7B
# $Model = "gemma-2b"    # Uncomment for Gemma-2B

# Find the running container ID (generic for different models)
Write-Host "Checking if a container for AI models is running..."
$ContainerID = docker ps --format "{{.ID}} {{.Names}}" | Where-Object { $_ -match "ollama" } | ForEach-Object { ($_ -split " ")[0] }

if ($null -ne $ContainerID) {
    Write-Host "Container detected: $ContainerID"
    Write-Host "Entering the container and pulling model: $Model..."
    docker exec -it $ContainerID ollama pull $Model
    Write-Host "Command executed. Exiting container..."
} else {
    Write-Host "No running container found!"
}

Write-Host "Execution complete."
