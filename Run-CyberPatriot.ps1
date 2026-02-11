#Requires -RunAsAdministrator
<#
.SYNOPSIS
    CyberPatriot Master Control Script
.DESCRIPTION
    Orchestrates all CyberPatriot automation and audit scripts in the recommended order.
    Provides a unified interface for running all security hardening and audit tasks.
.NOTES
    MUST BE RUN AS ADMINISTRATOR
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

function Show-Banner {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  CyberPatriot Automation Suite" -ForegroundColor Cyan
    Write-Host "  Master Control Script" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Menu {
    param([string]$Title = 'CyberPatriot Automation Menu')
    
    Write-Host "================ $Title ================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║   RECOMMENDED WORKFLOW (Step-by-Step)  ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host "  Step 0: Analyze README (Extract requirements)" -ForegroundColor Green
    Write-Host "  Step 1: Quick Audit (See current state)" -ForegroundColor Green
    Write-Host "  Step 2: Security Hardening (Auto-fix issues)" -ForegroundColor Green
    Write-Host "  Step 3: File Auditor (Find bad files)" -ForegroundColor Green
    Write-Host "  Step 4: User Auditor (Check accounts)" -ForegroundColor Green
    Write-Host "  Step 5: Windows Update (DO THIS LAST!)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║  QUICK START: Press [R] to run all!   ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "INDIVIDUAL SCRIPTS:" -ForegroundColor Green
    Write-Host "  [0] Analyze README - Parse competition requirements" -ForegroundColor White
    Write-Host "  [Q] Quick Audit - Fast overview of security issues" -ForegroundColor White
    Write-Host "  [A] Security Hardening - Run CyberPatriot-Auto.ps1" -ForegroundColor White
    Write-Host "  [S] Server Hardening - Run ServerHardening.ps1 (Windows Server only)" -ForegroundColor White
    Write-Host "  [F] File Auditor - Scan for unauthorized files/software" -ForegroundColor White
    Write-Host "  [U] User Auditor - Review user accounts and groups" -ForegroundColor White
    Write-Host ""
    Write-Host "UTILITIES:" -ForegroundColor Green
    Write-Host "  [L] View all log files" -ForegroundColor White
    Write-Host "  [C] Open checklist folder" -ForegroundColor White
    Write-Host "  [H] Open Quick Start guide" -ForegroundColor White
    Write-Host "  [W] Run Windows Update (DO THIS LAST!)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [R] ⭐ Run all recommended tasks (0-4 in sequence)" -ForegroundColor Cyan
    Write-Host "  [X] Exit" -ForegroundColor Gray
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
}

function Run-QuickAudit {
    Write-Host "`n[*] Running Quick Audit..." -ForegroundColor Cyan
    Write-Host "This provides a fast overview of the current security state." -ForegroundColor Gray
    Write-Host ""
    
    # Quick checks
    Write-Host "=== FIREWALL STATUS ===" -ForegroundColor Yellow
    try {
        $firewallProfiles = Get-NetFirewallProfile
        foreach ($profile in $firewallProfiles) {
            $status = if ($profile.Enabled) { "ENABLED" } else { "DISABLED" }
            $color = if ($profile.Enabled) { "Green" } else { "Red" }
            Write-Host "$($profile.Name): $status" -ForegroundColor $color
        }
    } catch {
        Write-Host "Could not check firewall status" -ForegroundColor Red
    }
    
    Write-Host "`n=== USER ACCOUNTS ===" -ForegroundColor Yellow
    try {
        $users = Get-LocalUser | Where-Object { $_.Enabled }
        Write-Host "Enabled users: $($users.Count)" -ForegroundColor Cyan
        foreach ($user in $users) {
            Write-Host "  - $($user.Name)" -ForegroundColor Gray
        }
        
        # Check for Guest/Admin
        $guest = Get-LocalUser -Name "Guest" -ErrorAction SilentlyContinue
        if ($guest -and $guest.Enabled) {
            Write-Host "  WARNING: Guest account is enabled!" -ForegroundColor Red
        }
        
        $admin = Get-LocalUser -Name "Administrator" -ErrorAction SilentlyContinue
        if ($admin -and $admin.Enabled) {
            Write-Host "  WARNING: Built-in Administrator is enabled!" -ForegroundColor Red
        }
    } catch {
        Write-Host "Could not check user accounts" -ForegroundColor Red
    }
    
    Write-Host "`n=== WINDOWS DEFENDER ===" -ForegroundColor Yellow
    try {
        $defender = Get-MpComputerStatus
        $rtStatus = if ($defender.RealTimeProtectionEnabled) { "ENABLED" } else { "DISABLED" }
        $rtColor = if ($defender.RealTimeProtectionEnabled) { "Green" } else { "Red" }
        Write-Host "Real-time Protection: $rtStatus" -ForegroundColor $rtColor
        Write-Host "Last Quick Scan: $($defender.QuickScanEndTime)" -ForegroundColor Gray
    } catch {
        Write-Host "Could not check Windows Defender status" -ForegroundColor Red
    }
    
    Write-Host "`n=== INSECURE SERVICES ===" -ForegroundColor Yellow
    $insecureServices = @("RemoteRegistry", "TermService", "ftpsvc", "SSDPSRV", "upnphost")
    foreach ($svcName in $insecureServices) {
        try {
            $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
            if ($svc) {
                $status = $svc.Status
                $startup = $svc.StartType
                $color = if ($status -eq "Running" -or $startup -eq "Automatic") { "Red" } else { "Green" }
                Write-Host "$($svcName): $status ($startup)" -ForegroundColor $color
            }
        } catch {
            # Service doesn't exist, which is fine
        }
    }
    
    Write-Host "`n=== AUTOMATIC UPDATES ===" -ForegroundColor Yellow
    try {
        $updateService = New-Object -ComObject Microsoft.Update.AutoUpdate
        $updateEnabled = $updateService.ServiceEnabled
        $color = if ($updateEnabled) { "Green" } else { "Red" }
        $status = if ($updateEnabled) { "ENABLED" } else { "DISABLED" }
        Write-Host "Automatic Updates: $status" -ForegroundColor $color
    } catch {
        Write-Host "Could not check automatic updates" -ForegroundColor Red
    }
    
    Write-Host "`n" 
    Write-Host "Quick audit complete!" -ForegroundColor Green
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Run-SecurityHardening {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Launching Security Hardening Script   ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This tool will:" -ForegroundColor Yellow
    Write-Host "  • Enable Windows Firewall" -ForegroundColor Gray
    Write-Host "  • Configure password policies" -ForegroundColor Gray
    Write-Host "  • Disable insecure services" -ForegroundColor Gray
    Write-Host "  • Block vulnerable ports" -ForegroundColor Gray
    Write-Host "  • Enable Windows Defender" -ForegroundColor Gray
    Write-Host ""
    
    $autoScript = Join-Path $ScriptPath "CyberPatriot-Auto.ps1"
    
    if (Test-Path $autoScript) {
        & $autoScript
        Write-Host ""
        Write-Host "✓ Security hardening complete!" -ForegroundColor Green
    } else {
        Write-Host "❌ ERROR: CyberPatriot-Auto.ps1 not found!" -ForegroundColor Red
        Write-Host "Expected location: $autoScript" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Run-AnalyzeReadme {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Launching README Analyzer...          ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This tool will:" -ForegroundColor Yellow
    Write-Host "  • Find the competition README file or shortcut" -ForegroundColor Gray
    Write-Host "  • Download content from web if it's a .lnk shortcut" -ForegroundColor Gray
    Write-Host "  • Allow manual paste if auto-download fails" -ForegroundColor Gray
    Write-Host "  • Extract authorized users, software, and services" -ForegroundColor Gray
    Write-Host ""
    
    $readmeScript = Join-Path $ScriptPath "AnalyzeReadme.ps1"
    
    if (Test-Path $readmeScript) {
        & $readmeScript
        Write-Host ""
        Write-Host "✓ README analysis complete!" -ForegroundColor Green
    } else {
        Write-Host "❌ ERROR: AnalyzeReadme.ps1 not found!" -ForegroundColor Red
        Write-Host "Expected location: $readmeScript" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Run-ServerHardening {
    Write-Host "`n[*] Launching Server Hardening Script..." -ForegroundColor Cyan
    $serverScript = Join-Path $ScriptPath "ServerHardening.ps1"
    
    if (Test-Path $serverScript) {
        & $serverScript
    } else {
        Write-Host "ERROR: ServerHardening.ps1 not found!" -ForegroundColor Red
        Write-Host "Expected location: $serverScript" -ForegroundColor Red
        Write-Host "Press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Run-FileAuditor {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Launching File Auditor                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This tool will:" -ForegroundColor Yellow
    Write-Host "  • Scan for unauthorized software" -ForegroundColor Gray
    Write-Host "  • Find media files (music, videos)" -ForegroundColor Gray
    Write-Host "  • Check for suspicious processes" -ForegroundColor Gray
    Write-Host "  • Review startup items" -ForegroundColor Gray
    Write-Host "  • Generate audit report" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⚠️  Note: This tool only reports findings - you must delete files manually!" -ForegroundColor Yellow
    Write-Host ""
    
    $fileAuditScript = Join-Path $ScriptPath "FileAuditor.ps1"
    
    if (Test-Path $fileAuditScript) {
        & $fileAuditScript
        Write-Host ""
        Write-Host "✓ File audit complete!" -ForegroundColor Green
    } else {
        Write-Host "❌ ERROR: FileAuditor.ps1 not found!" -ForegroundColor Red
        Write-Host "Expected location: $fileAuditScript" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Run-UserAuditor {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  Launching User Auditor                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This tool will:" -ForegroundColor Yellow
    Write-Host "  • List all user accounts" -ForegroundColor Gray
    Write-Host "  • Check against authorized users from README" -ForegroundColor Gray
    Write-Host "  • Show group memberships" -ForegroundColor Gray
    Write-Host "  • Verify admin access" -ForegroundColor Gray
    Write-Host "  • Check password policies" -ForegroundColor Gray
    Write-Host ""
    
    $userAuditScript = Join-Path $ScriptPath "UserAuditor.ps1"
    
    if (Test-Path $userAuditScript) {
        & $userAuditScript
        Write-Host ""
        Write-Host "✓ User audit complete!" -ForegroundColor Green
    } else {
        Write-Host "❌ ERROR: UserAuditor.ps1 not found!" -ForegroundColor Red
        Write-Host "Expected location: $userAuditScript" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function View-AllLogs {
    Write-Host "`n[*] Finding log files..." -ForegroundColor Cyan
    $logs = Get-ChildItem -Path $ScriptPath -Filter "*.txt" | Where-Object { $_.Name -like "*Audit*" -or $_.Name -like "*Log*" }
    
    if ($logs.Count -eq 0) {
        Write-Host "No log files found." -ForegroundColor Yellow
    } else {
        Write-Host "Found $($logs.Count) log file(s):" -ForegroundColor Green
        $logs | Format-Table Name, LastWriteTime, @{Name='Size(KB)';Expression={[math]::Round($_.Length/1KB,2)}} -AutoSize
        
        Write-Host "`nEnter log number to view (or press Enter to skip): " -NoNewline
        $choice = Read-Host
        
        if ($choice -match '^\d+$' -and [int]$choice -gt 0 -and [int]$choice -le $logs.Count) {
            $selectedLog = $logs[[int]$choice - 1]
            Start-Process notepad.exe -ArgumentList $selectedLog.FullName
        }
    }
    
    Write-Host "`nPress any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Open-ChecklistFolder {
    Write-Host "`n[*] Opening checklist folder..." -ForegroundColor Cyan
    $checklistPath = Join-Path $ScriptPath "checklist"
    
    if (Test-Path $checklistPath) {
        Start-Process explorer.exe -ArgumentList $checklistPath
        Write-Host "Checklist folder opened in Explorer." -ForegroundColor Green
    } else {
        Write-Host "ERROR: Checklist folder not found!" -ForegroundColor Red
    }
    
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Open-QuickStartGuide {
    Write-Host "`n[*] Opening Quick Start guide..." -ForegroundColor Cyan
    $guidePath = Join-Path $ScriptPath "QUICK_START.md"
    
    if (Test-Path $guidePath) {
        Start-Process notepad.exe -ArgumentList $guidePath
        Write-Host "Quick Start guide opened." -ForegroundColor Green
    } else {
        Write-Host "ERROR: QUICK_START.md not found!" -ForegroundColor Red
    }
    
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Run-WindowsUpdate {
    Write-Host "`n[*] Opening Windows Update..." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  WINDOWS UPDATE - RUN THIS LAST!" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Windows Update should be run AFTER:" -ForegroundColor Cyan
    Write-Host "  ✓ All security hardening is complete" -ForegroundColor Gray
    Write-Host "  ✓ All unauthorized files are deleted" -ForegroundColor Gray
    Write-Host "  ✓ All unauthorized users are removed" -ForegroundColor Gray
    Write-Host "  ✓ All manual tasks are finished" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Opening Windows Update Settings..." -ForegroundColor Green
    Write-Host ""
    
    # Open Windows Update settings
    Start-Process "ms-settings:windowsupdate"
    
    Write-Host "In the Windows Update window:" -ForegroundColor Yellow
    Write-Host "  1. Click 'Check for updates'" -ForegroundColor Gray
    Write-Host "  2. Install all available updates" -ForegroundColor Gray
    Write-Host "  3. Restart if required" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Run-AllTasks {
    Write-Host "`n" 
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║  RUNNING ALL RECOMMENDED TASKS         ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "This will run the following in sequence:" -ForegroundColor Cyan
    Write-Host "  ✓ Step 0: Analyze README" -ForegroundColor Gray
    Write-Host "  ✓ Step 1: Quick Audit" -ForegroundColor Gray
    Write-Host "  ✓ Step 2: Security Hardening" -ForegroundColor Gray
    Write-Host "  ✓ Step 3: File Auditor" -ForegroundColor Gray
    Write-Host "  ✓ Step 4: User Auditor" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⏱️  Estimated time: 5-10 minutes" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to start, or Ctrl+C to cancel..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    Write-Host ""
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "[STEP 0/5] Analyzing README..." -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Run-AnalyzeReadme
    Write-Host "✓ Step 0 complete!" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "[STEP 1/5] Running Quick Audit..." -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Run-QuickAudit
    Write-Host "✓ Step 1 complete!" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "[STEP 2/5] Running Security Hardening..." -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Run-SecurityHardening
    Write-Host "✓ Step 2 complete!" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "[STEP 3/5] Running File Auditor..." -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Run-FileAuditor
    Write-Host "✓ Step 3 complete!" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "[STEP 4/5] Running User Auditor..." -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Run-UserAuditor
    Write-Host "✓ Step 4 complete!" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║    AUTOMATED TASKS COMPLETE! ✓         ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "  1. ✓ Review the log files (Option L)" -ForegroundColor Gray
    Write-Host "  2. ✓ Delete unauthorized files found by File Auditor" -ForegroundColor Gray
    Write-Host "  3. ✓ Adjust user accounts as needed" -ForegroundColor Gray
    Write-Host "  4. ✓ Complete manual tasks from checklist" -ForegroundColor Gray
    Write-Host "  5. ⚠️  RUN WINDOWS UPDATE (Option W) - DO THIS LAST!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to return to menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Main script execution
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Main menu loop
do {
    Show-Banner
    Show-Menu
    
    Write-Host "Select an option: " -NoNewline -ForegroundColor Cyan
    $choice = Read-Host
    
    switch ($choice.ToUpper()) {
        '0' { Run-AnalyzeReadme }
        'Q' { Run-QuickAudit }
        'A' { Run-SecurityHardening }
        'S' { Run-ServerHardening }
        'F' { Run-FileAuditor }
        'U' { Run-UserAuditor }
        'L' { View-AllLogs }
        'C' { Open-ChecklistFolder }
        'H' { Open-QuickStartGuide }
        'W' { Run-WindowsUpdate }
        'R' { Run-AllTasks }
        'X' { 
            Write-Host "`nExiting... Good luck with CyberPatriot!" -ForegroundColor Green
            break
        }
        default {
            Write-Host "`nInvalid option. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($choice.ToUpper() -ne 'X')
