# =============================================
#  1Acces Print Collector Agent - Installation (Windows)
# =============================================
# Telecharge le binaire depuis GitHub Releases (fallback erp.1acces.com/downloads),
# verifie la signature Authenticode si presente et installe un service Windows via sc.exe.
#
# Usage (PowerShell admin) :
#   powershell -ExecutionPolicy Bypass -File install-windows.ps1
# =============================================

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

Write-Host "============================================="
Write-Host "  1Acces Print Collector Agent - Installation"
Write-Host "============================================="
Write-Host ""

$InstallDir = "C:\1Acces\PrintAgent"
$Binary = "print-agent-win-x64.exe"
$Version = if ($env:PRINT_AGENT_VERSION) { $env:PRINT_AGENT_VERSION } else { "latest" }

if ($Version -eq "latest") {
    $GithubUrl = "https://github.com/Ipercom/print-agent-releases/releases/latest/download/$Binary"
} else {
    $GithubUrl = "https://github.com/Ipercom/print-agent-releases/releases/download/$Version/$Binary"
}
$FallbackUrl = "https://erp.1acces.com/downloads/$Binary"

# 1. Creer le dossier
Write-Host "[1/5] Creation du dossier $InstallDir..."
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

# 2. Telecharger
Write-Host "[2/5] Telechargement du binaire (version: $Version)..."
$TargetPath = Join-Path $InstallDir $Binary

try {
    Invoke-WebRequest -Uri $GithubUrl -OutFile $TargetPath -UseBasicParsing
} catch {
    Write-Warning "Echec GitHub Releases ($($_.Exception.Message)), fallback sur erp.1acces.com..."
    Invoke-WebRequest -Uri $FallbackUrl -OutFile $TargetPath -UseBasicParsing
}

# 3. Verifier la signature Authenticode
Write-Host "[3/5] Verification de la signature..."
$Sig = Get-AuthenticodeSignature -FilePath $TargetPath
if ($Sig.Status -eq "Valid") {
    Write-Host "     Signature valide : $($Sig.SignerCertificate.Subject)"
} else {
    Write-Warning "Signature : $($Sig.Status). Le binaire peut declencher SmartScreen."
    Write-Warning "Si Windows bloque l'execution : clic droit > Proprietes > Debloquer."
}

# 4. Config
Write-Host "[4/5] Generation de la configuration..."
$ConfigPath = Join-Path $InstallDir "config.json"
if (-not (Test-Path $ConfigPath)) {
    $Config = @{
        apiUrl = "https://erp-pme-api.onrender.com/api/printing"
        agentKey = ""
        agentId = ""
        agentName = "Agent Windows"
        pollIntervalMinutes = 15
        snmpCommunity = "public"
        snmpTimeout = 5000
        networkRange = "192.168.1.0/24"
        printerIps = @()
    }
    $Config | ConvertTo-Json | Set-Content -Path $ConfigPath -Encoding UTF8
}

# 5. Installer en service Windows
Write-Host "[5/5] Installation du service Windows..."
$ServiceName = "1AccesPrintAgent"
$existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "     Service existant detecte, arret puis suppression..."
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    sc.exe delete $ServiceName | Out-Null
    Start-Sleep -Seconds 2
}

sc.exe create $ServiceName binPath= "`"$TargetPath`"" start= auto DisplayName= "1Acces Print Collector Agent" | Out-Null
sc.exe description $ServiceName "Agent de collecte volumes impression 1Acces (SNMP + API 1Acces)" | Out-Null

Write-Host ""
Write-Host "============================================="
Write-Host "  Installation terminee !"
Write-Host "============================================="
Write-Host ""
Write-Host "  1. Editez $ConfigPath"
Write-Host "     (renseignez agentKey et agentId generes sur erp.1acces.com)"
Write-Host ""
Write-Host "  2. Demarrez le service :"
Write-Host "     Start-Service $ServiceName"
Write-Host ""
Write-Host "  3. Voir le statut :"
Write-Host "     Get-Service $ServiceName"
Write-Host ""
Write-Host "============================================="
