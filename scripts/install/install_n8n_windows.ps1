# ============================================================================
# n8n One-Step Installation Script for Windows (PowerShell)
# Author: Chetansingh Rajput
# Description: Automatically installs n8n with all prerequisites on Windows
# Requires: PowerShell 5.1+ (Run as Administrator)
# ============================================================================

#Requires -RunAsAdministrator

# Configuration
$MIN_NODE_VERSION = "18.10.0"
$N8N_PORT = if ($env:N8N_PORT) { $env:N8N_PORT } else { "5678" }
$NODE_INSTALLER_URL = "https://nodejs.org/dist/v20.11.0/node-v20.11.0-x64.msi"

# ============================================================================
# Helper Functions
# ============================================================================

function Write-Header {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║          n8n One-Step Installation Script (Windows)          ║" -ForegroundColor Blue
    Write-Host "║          Automate your workflow automation!                  ║" -ForegroundColor Blue
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Blue
}

# ============================================================================
# Check Prerequisites
# ============================================================================

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Compare-Version {
    param(
        [string]$Version1,
        [string]$Version2
    )
    $v1 = [version]$Version1
    $v2 = [version]$Version2
    return $v1 -ge $v2
}

# ============================================================================
# Node.js Installation
# ============================================================================

function Test-NodeInstalled {
    Write-Step "Checking Node.js installation..."
    
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            $version = $nodeVersion -replace 'v', ''
            Write-Info "Found Node.js version: $version"
            
            if (Compare-Version -Version1 $version -Version2 $MIN_NODE_VERSION) {
                Write-Success "Node.js version is compatible (>= $MIN_NODE_VERSION)"
                return "current"
            } else {
                Write-Warning-Custom "Node.js version is too old. Minimum required: $MIN_NODE_VERSION"
                return "outdated"
            }
        }
    } catch {
        Write-Warning-Custom "Node.js is not installed"
        return "missing"
    }
    return "missing"
}

function Install-NodeJs {
    Write-Step "Installing Node.js..."
    
    $installerPath = "$env:TEMP\node-installer.msi"
    
    Write-Info "Downloading Node.js installer..."
    try {
        Invoke-WebRequest -Uri $NODE_INSTALLER_URL -OutFile $installerPath -UseBasicParsing
        Write-Success "Download complete"
    } catch {
        Write-Error-Custom "Failed to download Node.js installer"
        Write-Info "Please download manually from: https://nodejs.org/"
        exit 1
    }
    
    Write-Info "Running Node.js installer..."
    Write-Warning-Custom "Please follow the installation wizard..."
    
    Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /qn /norestart" -Wait -NoNewWindow
    
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    # Wait a moment for installation to complete
    Start-Sleep -Seconds 3
    
    # Verify installation
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            Write-Success "Node.js installed successfully: $nodeVersion"
            Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
            return $true
        }
    } catch {
        Write-Error-Custom "Node.js installation may have failed"
        Write-Info "Please restart PowerShell and run this script again"
        exit 1
    }
    
    return $false
}

# ============================================================================
# System Checks
# ============================================================================

function Test-SystemResources {
    Write-Step "Checking system resources..."
    
    $computerSystem = Get-CimInstance Win32_ComputerSystem
    $totalRAM = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
    
    Write-Info "Total RAM: $totalRAM GB"
    
    if ($totalRAM -lt 4) {
        Write-Warning-Custom "Less than 4GB RAM detected. n8n may run slowly"
    } else {
        Write-Success "Sufficient RAM available"
    }
}

function Test-PortAvailable {
    param([int]$Port)
    
    Write-Step "Checking if port $Port is available..."
    
    $tcpConnection = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    
    if ($tcpConnection) {
        Write-Warning-Custom "Port $Port is already in use"
        Write-Info "You can use a different port by setting: `$env:N8N_PORT=5679"
        
        $response = Read-Host "Continue anyway? (y/n)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            exit 1
        }
    } else {
        Write-Success "Port $Port is available"
    }
}

# ============================================================================
# n8n Installation
# ============================================================================

function Install-N8n {
    Write-Step "Installing n8n globally..."
    
    try {
        npm install -g n8n
        Write-Success "n8n installed successfully!"
        return $true
    } catch {
        Write-Error-Custom "Failed to install n8n"
        Write-Info "Error: $_"
        return $false
    }
}

# ============================================================================
# Configuration
# ============================================================================

function New-N8nConfig {
    Write-Step "Creating n8n configuration..."
    
    $n8nDir = Join-Path $env:USERPROFILE ".n8n"
    
    if (-not (Test-Path $n8nDir)) {
        New-Item -ItemType Directory -Path $n8nDir -Force | Out-Null
    }
    
    $envFile = Join-Path $n8nDir ".env"
    
    if (-not (Test-Path $envFile)) {
        $timezone = (Get-TimeZone).Id
        
        $configContent = @"
# n8n Configuration
# Generated by n8n-installer

# Basic Authentication
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=change_this_password

# Server Configuration
N8N_PORT=$N8N_PORT
N8N_PROTOCOL=http
N8N_HOST=localhost

# Timezone
GENERIC_TIMEZONE=$timezone

# Execution Mode
EXECUTIONS_MODE=regular

# Security
N8N_BLOCK_ENV_ACCESS_IN_NODE=true
"@
        
        $configContent | Out-File -FilePath $envFile -Encoding UTF8
        Write-Success "Configuration file created at: $envFile"
        Write-Warning-Custom "Please change the default password in: $envFile"
    } else {
        Write-Info "Configuration file already exists, skipping..."
    }
}

# ============================================================================
# Launch Scripts
# ============================================================================

function New-LaunchScript {
    Write-Step "Creating convenient launch script..."
    
    $scriptPath = Join-Path $env:USERPROFILE "start-n8n.bat"
    
    $scriptContent = @"
@echo off
echo Starting n8n...
n8n start
pause
"@
    
    $scriptContent | Out-File -FilePath $scriptPath -Encoding ASCII
    Write-Success "Launch script created: $scriptPath"
    Write-Info "Double-click this file to start n8n anytime!"
}

# ============================================================================
# Firewall Configuration
# ============================================================================

function Set-FirewallRule {
    Write-Step "Configuring Windows Firewall..."
    
    try {
        $ruleName = "n8n Workflow Automation"
        $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
        
        if (-not $existingRule) {
            New-NetFirewallRule -DisplayName $ruleName `
                               -Direction Inbound `
                               -LocalPort $N8N_PORT `
                               -Protocol TCP `
                               -Action Allow `
                               -ErrorAction Stop | Out-Null
            Write-Success "Firewall rule created for port $N8N_PORT"
        } else {
            Write-Info "Firewall rule already exists"
        }
    } catch {
        Write-Warning-Custom "Could not configure firewall rule"
        Write-Info "You may need to manually allow port $N8N_PORT in Windows Firewall"
    }
}

# ============================================================================
# Browser Launch
# ============================================================================

function Start-N8nAndOpenBrowser {
    Write-Step "Starting n8n..."
    
    Write-Info "n8n is starting up (this takes a few seconds)..."
    
    # Start n8n in background
    $job = Start-Job -ScriptBlock {
        n8n start
    }
    
    # Wait for n8n to be ready
    Write-Info "Waiting for n8n to be ready..."
    $maxAttempts = 30
    $attempt = 0
    $isReady = $false
    
    while ($attempt -lt $maxAttempts -and -not $isReady) {
        Start-Sleep -Seconds 1
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$N8N_PORT" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                $isReady = $true
            }
        } catch {
            # Keep waiting
        }
        $attempt++
        Write-Host "." -NoNewline -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    if ($isReady) {
        Write-Success "n8n is ready!"
        Write-Info "Opening browser..."
        Start-Process "http://localhost:$N8N_PORT"
        
        Write-Host ""
        Write-Host "n8n is now running in the background!" -ForegroundColor Green
        Write-Host "Keep this PowerShell window open to keep n8n running." -ForegroundColor Yellow
        Write-Host "Press Ctrl+C to stop n8n when you're done." -ForegroundColor Yellow
        Write-Host ""
        
        # Keep the job running
        Wait-Job -Job $job
    } else {
        Write-Warning-Custom "n8n took too long to start"
        Write-Info "Try starting it manually with: n8n start"
        Write-Info "Then open: http://localhost:$N8N_PORT"
    }
}

function Show-PostInstall {
    param([bool]$AutoStart = $false)
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║               Installation Complete!                         ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Success "n8n is now installed and ready to use!"
    Write-Host ""
    
    if (-not $AutoStart) {
        Write-Host "Quick Start:" -ForegroundColor Blue
        Write-Host "  1. Start n8n:"
        Write-Host "     n8n start" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  2. Or use the launch script:"
        Write-Host "     Double-click: $env:USERPROFILE\start-n8n.bat" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  3. Open your browser:"
        Write-Host "     http://localhost:$N8N_PORT" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  4. Login credentials:"
        Write-Host "     Username: admin" -ForegroundColor Yellow
        Write-Host "     Password: change_this_password" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "⚠ IMPORTANT: Change your password in $env:USERPROFILE\.n8n\.env" -ForegroundColor Red
        Write-Host ""
        Write-Host "Useful Commands:" -ForegroundColor Blue
        Write-Host "  • Start n8n:     n8n start" -ForegroundColor White
        Write-Host "  • Custom port:   n8n start --port 5679" -ForegroundColor White
        Write-Host "  • Open browser:  n8n start -o" -ForegroundColor White
        Write-Host ""
    }
    
    Write-Host "Documentation:" -ForegroundColor Blue
    Write-Host "  • Official docs: https://docs.n8n.io/"
    Write-Host "  • GitHub repo:   https://github.com/cloudbunny17/n8n.git"
    Write-Host ""
    Write-Host "Happy Automating! 🚀" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# Main Installation Flow
# ============================================================================

function Main {
    Clear-Host
    Write-Header
    
    # Check if running as administrator
    if (-not (Test-Administrator)) {
        Write-Error-Custom "This script must be run as Administrator"
        Write-Info "Right-click PowerShell and select 'Run as Administrator'"
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    Write-Success "Running with Administrator privileges"
    
    # Check and install Node.js
    $nodeStatus = Test-NodeInstalled
    
    if ($nodeStatus -eq "missing") {
        Write-Warning-Custom "Node.js is not installed"
        $response = Read-Host "Install Node.js now? (y/n)"
        
        if ($response -eq 'y' -or $response -eq 'Y') {
            Install-NodeJs
            
            # Verify installation
            $nodeStatus = Test-NodeInstalled
            if ($nodeStatus -eq "missing") {
                Write-Error-Custom "Node.js installation failed"
                Read-Host "Press Enter to exit"
                exit 1
            }
        } else {
            Write-Error-Custom "Node.js is required to run n8n"
            Read-Host "Press Enter to exit"
            exit 1
        }
    }
    elseif ($nodeStatus -eq "outdated") {
        Write-Warning-Custom "Your Node.js version is outdated"
        $response = Read-Host "Would you like to update Node.js? (y/n)"
        
        if ($response -eq 'y' -or $response -eq 'Y') {
            Write-Info "Updating Node.js..."
            Install-NodeJs
            
            # Verify update
            $nodeStatus = Test-NodeInstalled
            if ($nodeStatus -ne "current") {
                Write-Warning-Custom "Node.js update may have failed, but continuing..."
            }
        } else {
            Write-Warning-Custom "Continuing with outdated Node.js (may cause issues)"
        }
    }
    
    # Check system resources
    Test-SystemResources
    
    # Check port availability
    Test-PortAvailable -Port $N8N_PORT
    
    # Install n8n
    if (-not (Install-N8n)) {
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Create configuration
    New-N8nConfig
    
    # Create launch script
    New-LaunchScript
    
    # Configure firewall
    Set-FirewallRule
    
    # Ask if user wants to start n8n now
    Write-Host ""
    $startNow = Read-Host "Would you like to start n8n now? (y/n)"
    
    if ($startNow -eq 'y' -or $startNow -eq 'Y') {
        Show-PostInstall -AutoStart $true
        Write-Host ""
        Write-Host "⚠ IMPORTANT: Change default password in $env:USERPROFILE\.n8n\.env" -ForegroundColor Red
        Write-Host "   Username: admin" -ForegroundColor Yellow
        Write-Host "   Password: change_this_password" -ForegroundColor Yellow
        Write-Host ""
        Start-N8nAndOpenBrowser
    } else {
        Show-PostInstall -AutoStart $false
        Read-Host "Press Enter to exit"
    }
}

# ============================================================================
# Run Main
# ============================================================================

Main