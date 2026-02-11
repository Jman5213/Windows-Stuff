#Requires -RunAsAdministrator
<#
.SYNOPSIS
    README Parser for CyberPatriot Competition Images
.DESCRIPTION
    Parses the competition README file to extract authorized users, allowed software,
    required services, and other configuration requirements.
    This ensures the automation scripts don't flag or remove items that are actually required.
.NOTES
    This parser handles common README formats from CyberPatriot competitions
#>

function Get-ShortcutTarget {
    <#
    .SYNOPSIS
        Extracts the target URL from a .lnk shortcut file
    #>
    param(
        [string]$ShortcutPath
    )
    
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($ShortcutPath)
        $target = $shortcut.TargetPath
        
        # Also check Arguments which might contain the URL
        if ($shortcut.Arguments) {
            $target = $shortcut.Arguments
        }
        
        # If TargetPath is a browser, the URL is likely in Arguments
        if ($target -like "*chrome.exe*" -or $target -like "*firefox.exe*" -or $target -like "*msedge.exe*" -or $target -like "*iexplore.exe*") {
            $target = $shortcut.Arguments
        }
        
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shortcut) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
        
        return $target
    } catch {
        Write-Host "Error reading shortcut: $_" -ForegroundColor Red
        return $null
    }
}

function Download-WebContent {
    <#
    .SYNOPSIS
        Downloads content from a URL
    #>
    param(
        [string]$Url
    )
    
    try {
        Write-Host "Downloading README from: $Url" -ForegroundColor Cyan
        
        # Use Invoke-WebRequest to download the content
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 30
        
        # Try to extract text from HTML
        $content = $response.Content
        
        # Enhanced HTML cleanup for better parsing
        # Remove script and style tags first
        $content = $content -replace '<script[^>]*>.*?</script>', ''
        $content = $content -replace '<style[^>]*>.*?</style>', ''
        
        # Preserve common structural elements by adding newlines
        $content = $content -replace '<br\s*/?>', "`n"
        $content = $content -replace '<p\s*[^>]*>', "`n"
        $content = $content -replace '</p>', "`n"
        $content = $content -replace '<div\s*[^>]*>', "`n"
        $content = $content -replace '</div>', "`n"
        $content = $content -replace '<li\s*[^>]*>', "`n- "
        $content = $content -replace '</li>', "`n"
        $content = $content -replace '<h[1-6][^>]*>', "`n"
        $content = $content -replace '</h[1-6]>', "`n"
        $content = $content -replace '<tr\s*[^>]*>', "`n"
        $content = $content -replace '</tr>', "`n"
        
        # Remove all remaining HTML tags
        $content = $content -replace '<[^>]+>', ' '
        
        # Decode HTML entities more comprehensively
        $content = $content -replace '&nbsp;', ' '
        $content = $content -replace '&amp;', '&'
        $content = $content -replace '&lt;', '<'
        $content = $content -replace '&gt;', '>'
        $content = $content -replace '&quot;', '"'
        $content = $content -replace '&#39;', "'"
        $content = $content -replace '&apos;', "'"
        $content = $content -replace '&mdash;', '-'
        $content = $content -replace '&ndash;', '-'
        $content = $content -replace '&bull;', '•'
        $content = $content -replace '&#8226;', '•'
        $content = $content -replace '&#(\d+);', { param($m) [char][int]$m.Groups[1].Value }
        
        # Clean up extra whitespace while preserving structure
        $content = $content -replace '[ \t]+', ' '
        $content = $content -replace ' *\n *', "`n"
        $content = $content -replace '\n\s*\n\s*\n+', "`n`n"
        
        return $content.Trim()
    } catch {
        Write-Host "Error downloading content: $_" -ForegroundColor Red
        return $null
    }
}

function Find-CompetitionReadme {
    <#
    .SYNOPSIS
        Locates the competition README file or shortcut on the system
    .DESCRIPTION
        Searches common locations for README files/shortcuts (Desktop, Documents, root of C:)
        Handles both text files and .lnk shortcuts to websites
    #>
    
    $searchLocations = @(
        "$env:USERPROFILE\Desktop\README*",
        "$env:USERPROFILE\Documents\README*",
        "C:\README*",
        "$env:PUBLIC\Desktop\README*",
        "$env:USERPROFILE\Desktop\Readme*",
        "$env:USERPROFILE\Documents\Readme*",
        "C:\Readme*",
        "$env:USERPROFILE\Desktop\*readme*",
        "$env:PUBLIC\Desktop\*readme*"
    )
    
    foreach ($location in $searchLocations) {
        $files = Get-ChildItem -Path $location -ErrorAction SilentlyContinue
        if ($files) {
            # Return the first README found (could be .txt, .lnk, .url, etc.)
            return $files[0].FullName
        }
    }
    
    return $null
}

function Parse-CompetitionReadme {
    <#
    .SYNOPSIS
        Parses the competition README file
    .DESCRIPTION
        Extracts authorized users, allowed software, required services, and other requirements
    .PARAMETER ReadmePath
        Path to the README file. If not provided, will attempt to find it automatically.
    .PARAMETER ManualContent
        Manually provided README content (use this if automatic download fails)
    #>
    param(
        [string]$ReadmePath,
        [string]$ManualContent
    )
    
    $content = $null
    $isShortcut = $false
    $targetUrl = $null
    
    # If manual content is provided, use it directly
    if ($ManualContent) {
        Write-Host "Using manually provided README content" -ForegroundColor Green
        $content = $ManualContent
        $ReadmePath = "(Manual Input)"
    }
    else {
        # Try to find README if path not provided
        if (-not $ReadmePath -or -not (Test-Path $ReadmePath)) {
            Write-Host "Searching for competition README..." -ForegroundColor Cyan
            $ReadmePath = Find-CompetitionReadme
            
            if (-not $ReadmePath) {
                Write-Host "WARNING: Could not find competition README file or shortcut!" -ForegroundColor Yellow
                Write-Host "You can paste the content manually when prompted" -ForegroundColor Yellow
                
                # Prompt for manual input
                Write-Host ""
                Write-Host "Would you like to paste the README content manually? (Y/N): " -NoNewline -ForegroundColor Cyan
                $response = Read-Host
                
                if ($response -eq 'Y' -or $response -eq 'y') {
                    Write-Host ""
                    Write-Host "========================================" -ForegroundColor Yellow
                    Write-Host "  MANUAL README PASTE MODE" -ForegroundColor Yellow
                    Write-Host "========================================" -ForegroundColor Yellow
                    Write-Host ""
                    Write-Host "OPTION 1 - Use Clipboard (Recommended):" -ForegroundColor Green
                    Write-Host "  1. Copy the README content from your browser (Ctrl+A, Ctrl+C)" -ForegroundColor Gray
                    Write-Host "  2. Return to this window" -ForegroundColor Gray
                    Write-Host "  3. Type 'C' and press Enter to read from clipboard" -ForegroundColor Gray
                    Write-Host ""
                    Write-Host "OPTION 2 - Manual Line-by-Line Paste:" -ForegroundColor Green
                    Write-Host "  1. Type 'M' and press Enter" -ForegroundColor Gray
                    Write-Host "  2. Paste or type the content" -ForegroundColor Gray
                    Write-Host "  3. Press Enter twice when done" -ForegroundColor Gray
                    Write-Host ""
                    Write-Host "Enter your choice (C for Clipboard, M for Manual): " -NoNewline -ForegroundColor Cyan
                    $inputMethod = Read-Host
                    
                    if ($inputMethod -eq 'C' -or $inputMethod -eq 'c') {
                        # Try to read from clipboard
                        try {
                            Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
                            $clipContent = [System.Windows.Forms.Clipboard]::GetText()
                            
                            if ($clipContent -and $clipContent.Length -gt 10) {
                                $content = $clipContent
                                Write-Host ""
                                Write-Host "✓ Successfully read $($content.Length) characters from clipboard!" -ForegroundColor Green
                                
                                # Show preview
                                $preview = $content.Substring(0, [Math]::Min(200, $content.Length))
                                Write-Host ""
                                Write-Host "Preview of first 200 characters:" -ForegroundColor Cyan
                                Write-Host "---" -ForegroundColor Gray
                                Write-Host $preview -ForegroundColor Gray
                                Write-Host "---" -ForegroundColor Gray
                                Write-Host ""
                                Write-Host "Does this look correct? (Y/N): " -NoNewline -ForegroundColor Yellow
                                $confirm = Read-Host
                                
                                if ($confirm -ne 'Y' -and $confirm -ne 'y') {
                                    Write-Host "Clipboard content rejected. Please try again." -ForegroundColor Yellow
                                    return $null
                                }
                            } else {
                                Write-Host ""
                                Write-Host "ERROR: Clipboard is empty or content is too short!" -ForegroundColor Red
                                Write-Host "Please copy the README content first, then run this script again." -ForegroundColor Yellow
                                return $null
                            }
                        } catch {
                            Write-Host ""
                            Write-Host "ERROR: Could not access clipboard: $_" -ForegroundColor Red
                            Write-Host "Falling back to manual paste method..." -ForegroundColor Yellow
                            Start-Sleep -Seconds 2
                            $inputMethod = 'M'
                        }
                    }
                    
                    if ($inputMethod -eq 'M' -or $inputMethod -eq 'm') {
                        Write-Host ""
                        Write-Host "Paste the README content below, then press Enter twice when done:" -ForegroundColor Yellow
                        Write-Host "(You can paste multiple lines at once with Ctrl+V or right-click)" -ForegroundColor Gray
                        Write-Host ""
                        
                        $lines = @()
                        $emptyLineCount = 0
                        
                        while ($true) {
                            $line = Read-Host
                            
                            if ($line -eq "") {
                                $emptyLineCount++
                                if ($emptyLineCount -ge 2) {
                                    break
                                }
                                $lines += $line
                            } else {
                                $emptyLineCount = 0
                                $lines += $line
                            }
                        }
                        
                        $content = $lines -join "`n"
                    }
                    
                    $ReadmePath = "(Manual Input)"
                    
                    # Validate content
                    if (-not $content -or $content.Length -lt 10) {
                        Write-Host ""
                        Write-Host "ERROR: No content was provided or content is too short!" -ForegroundColor Red
                        Write-Host "Please ensure you've copied the README content." -ForegroundColor Yellow
                        return $null
                    }
                    
                    # Clean up any HTML if it was pasted from a web page
                    if ($content -match '<html|<div|<span|<p>|<br') {
                        Write-Host ""
                        Write-Host "Detected HTML content - cleaning up..." -ForegroundColor Cyan
                        
                        # Apply HTML cleanup
                        $content = $content -replace '<script[^>]*>.*?</script>', ''
                        $content = $content -replace '<style[^>]*>.*?</style>', ''
                        $content = $content -replace '<br\s*/?>', "`n"
                        $content = $content -replace '<p\s*[^>]*>', "`n"
                        $content = $content -replace '</p>', "`n"
                        $content = $content -replace '<div\s*[^>]*>', "`n"
                        $content = $content -replace '</div>', "`n"
                        $content = $content -replace '<li\s*[^>]*>', "`n- "
                        $content = $content -replace '</li>', "`n"
                        $content = $content -replace '<h[1-6][^>]*>', "`n"
                        $content = $content -replace '</h[1-6]>', "`n"
                        $content = $content -replace '<[^>]+>', ' '
                        
                        # Decode HTML entities
                        $content = $content -replace '&nbsp;', ' '
                        $content = $content -replace '&amp;', '&'
                        $content = $content -replace '&lt;', '<'
                        $content = $content -replace '&gt;', '>'
                        $content = $content -replace '&quot;', '"'
                        $content = $content -replace '&#39;', "'"
                        $content = $content -replace '&bull;', '•'
                        
                        # Clean up whitespace
                        $content = $content -replace '[ \t]+', ' '
                        $content = $content -replace ' *\n *', "`n"
                        $content = $content -replace '\n\s*\n\s*\n+', "`n`n"
                        $content = $content.Trim()
                        
                        Write-Host "HTML cleanup complete!" -ForegroundColor Green
                    }
                    
                    Write-Host ""
                    Write-Host "✓ Received $($content.Length) characters of README content" -ForegroundColor Green
                    
                    # Count potential sections for validation
                    $sectionCount = 0
                    if ($content -match '(?i)user') { $sectionCount++ }
                    if ($content -match '(?i)software|program') { $sectionCount++ }
                    if ($content -match '(?i)service') { $sectionCount++ }
                    if ($content -match '(?i)admin') { $sectionCount++ }
                    
                    Write-Host "Detected $sectionCount potential sections (users, software, services, etc.)" -ForegroundColor Cyan
                    
                } else {
                    return $null
                }
            }
        }
        
        # If we have a path and no manual content, try to load from file/shortcut
        if (-not $content -and $ReadmePath -ne "(Manual Input)") {
            Write-Host "Found README: $ReadmePath" -ForegroundColor Green
            
            # Check if it's a shortcut (.lnk or .url file)
            if ($ReadmePath -like "*.lnk" -or $ReadmePath -like "*.url") {
                $isShortcut = $true
                Write-Host "README is a shortcut - extracting target URL..." -ForegroundColor Cyan
                
                if ($ReadmePath -like "*.lnk") {
                    # Handle .lnk shortcut
                    $targetUrl = Get-ShortcutTarget -ShortcutPath $ReadmePath
                } else {
                    # Handle .url file (Internet Shortcut)
                    $urlContent = Get-Content -Path $ReadmePath -Raw
                    if ($urlContent -match 'URL=(.+)') {
                        $targetUrl = $matches[1].Trim()
                    }
                }
                
                if ($targetUrl) {
                    Write-Host "Target URL: $targetUrl" -ForegroundColor Green
                    
                    # Check if it's a web URL
                    if ($targetUrl -match '^https?://') {
                        Write-Host "Attempting to download README from web..." -ForegroundColor Cyan
                        $content = Download-WebContent -Url $targetUrl
                        
                        if (-not $content) {
                            Write-Host ""
                            Write-Host "ERROR: Could not download README from URL" -ForegroundColor Red
                            Write-Host "This could be due to:" -ForegroundColor Yellow
                            Write-Host "  - No internet connectivity" -ForegroundColor Gray
                            Write-Host "  - Firewall blocking the request" -ForegroundColor Gray
                            Write-Host "  - The URL requires authentication" -ForegroundColor Gray
                            Write-Host ""
                            Write-Host "Would you like to paste the content manually instead? (Y/N): " -NoNewline -ForegroundColor Cyan
                            $response = Read-Host
                            
                            if ($response -eq 'Y' -or $response -eq 'y') {
                                Write-Host ""
                                Write-Host "========================================" -ForegroundColor Yellow
                                Write-Host "  MANUAL README PASTE MODE" -ForegroundColor Yellow
                                Write-Host "========================================" -ForegroundColor Yellow
                                Write-Host ""
                                Write-Host "Target URL: $targetUrl" -ForegroundColor Cyan
                                Write-Host ""
                                Write-Host "OPTION 1 - Use Clipboard (Recommended):" -ForegroundColor Green
                                Write-Host "  1. Open $targetUrl in your browser" -ForegroundColor Gray
                                Write-Host "  2. Copy all the text (Ctrl+A, Ctrl+C)" -ForegroundColor Gray
                                Write-Host "  3. Return to this window" -ForegroundColor Gray
                                Write-Host "  4. Type 'C' and press Enter to read from clipboard" -ForegroundColor Gray
                                Write-Host ""
                                Write-Host "OPTION 2 - Manual Line-by-Line Paste:" -ForegroundColor Green
                                Write-Host "  1. Type 'M' and press Enter" -ForegroundColor Gray
                                Write-Host "  2. Paste the content" -ForegroundColor Gray
                                Write-Host "  3. Press Enter twice when done" -ForegroundColor Gray
                                Write-Host ""
                                Write-Host "Enter your choice (C for Clipboard, M for Manual): " -NoNewline -ForegroundColor Cyan
                                $inputMethod = Read-Host
                                
                                if ($inputMethod -eq 'C' -or $inputMethod -eq 'c') {
                                    # Try to read from clipboard
                                    try {
                                        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
                                        $clipContent = [System.Windows.Forms.Clipboard]::GetText()
                                        
                                        if ($clipContent -and $clipContent.Length -gt 10) {
                                            $content = $clipContent
                                            Write-Host ""
                                            Write-Host "✓ Successfully read $($content.Length) characters from clipboard!" -ForegroundColor Green
                                            
                                            # Show preview
                                            $preview = $content.Substring(0, [Math]::Min(200, $content.Length))
                                            Write-Host ""
                                            Write-Host "Preview of first 200 characters:" -ForegroundColor Cyan
                                            Write-Host "---" -ForegroundColor Gray
                                            Write-Host $preview -ForegroundColor Gray
                                            Write-Host "---" -ForegroundColor Gray
                                            Write-Host ""
                                            Write-Host "Does this look correct? (Y/N): " -NoNewline -ForegroundColor Yellow
                                            $confirm = Read-Host
                                            
                                            if ($confirm -ne 'Y' -and $confirm -ne 'y') {
                                                Write-Host "Clipboard content rejected. Please try again." -ForegroundColor Yellow
                                                return $null
                                            }
                                        } else {
                                            Write-Host ""
                                            Write-Host "ERROR: Clipboard is empty or content is too short!" -ForegroundColor Red
                                            Write-Host "Please copy the README content first." -ForegroundColor Yellow
                                            return $null
                                        }
                                    } catch {
                                        Write-Host ""
                                        Write-Host "ERROR: Could not access clipboard: $_" -ForegroundColor Red
                                        Write-Host "Falling back to manual paste method..." -ForegroundColor Yellow
                                        Start-Sleep -Seconds 2
                                        $inputMethod = 'M'
                                    }
                                }
                                
                                if ($inputMethod -eq 'M' -or $inputMethod -eq 'm') {
                                    Write-Host ""
                                    Write-Host "Paste the README content below, then press Enter twice when done:" -ForegroundColor Yellow
                                    Write-Host "(You can paste multiple lines at once with Ctrl+V or right-click)" -ForegroundColor Gray
                                    Write-Host ""
                                    
                                    $lines = @()
                                    $emptyLineCount = 0
                                    
                                    while ($true) {
                                        $line = Read-Host
                                        
                                        if ($line -eq "") {
                                            $emptyLineCount++
                                            if ($emptyLineCount -ge 2) {
                                                break
                                            }
                                            $lines += $line
                                        } else {
                                            $emptyLineCount = 0
                                            $lines += $line
                                        }
                                    }
                                    
                                    $content = $lines -join "`n"
                                }
                                
                                # Validate and clean content
                                if (-not $content -or $content.Length -lt 10) {
                                    Write-Host ""
                                    Write-Host "ERROR: No content was provided or content is too short!" -ForegroundColor Red
                                    return $null
                                }
                                
                                # Clean up any HTML if present
                                if ($content -match '<html|<div|<span|<p>|<br') {
                                    Write-Host ""
                                    Write-Host "Detected HTML content - cleaning up..." -ForegroundColor Cyan
                                    
                                    $content = $content -replace '<script[^>]*>.*?</script>', ''
                                    $content = $content -replace '<style[^>]*>.*?</style>', ''
                                    $content = $content -replace '<br\s*/?>', "`n"
                                    $content = $content -replace '<p\s*[^>]*>', "`n"
                                    $content = $content -replace '</p>', "`n"
                                    $content = $content -replace '<div\s*[^>]*>', "`n"
                                    $content = $content -replace '</div>', "`n"
                                    $content = $content -replace '<li\s*[^>]*>', "`n- "
                                    $content = $content -replace '</li>', "`n"
                                    $content = $content -replace '<[^>]+>', ' '
                                    
                                    $content = $content -replace '&nbsp;', ' '
                                    $content = $content -replace '&amp;', '&'
                                    $content = $content -replace '&lt;', '<'
                                    $content = $content -replace '&gt;', '>'
                                    $content = $content -replace '&quot;', '"'
                                    $content = $content -replace '&#39;', "'"
                                    $content = $content -replace '&bull;', '•'
                                    
                                    $content = $content -replace '[ \t]+', ' '
                                    $content = $content -replace ' *\n *', "`n"
                                    $content = $content -replace '\n\s*\n\s*\n+', "`n`n"
                                    $content = $content.Trim()
                                    
                                    Write-Host "HTML cleanup complete!" -ForegroundColor Green
                                }
                                
                                Write-Host ""
                                Write-Host "✓ Received $($content.Length) characters of README content" -ForegroundColor Green
                            } else {
                                return $null
                            }
                        }
                    } else {
                        Write-Host "WARNING: Shortcut target is not a web URL: $targetUrl" -ForegroundColor Yellow
                        Write-Host "Attempting to read as local file..." -ForegroundColor Yellow
                        
                        if (Test-Path $targetUrl) {
                            $content = Get-Content -Path $targetUrl -Raw
                        } else {
                            Write-Host "ERROR: Target file not found: $targetUrl" -ForegroundColor Red
                            return $null
                        }
                    }
                } else {
                    Write-Host "ERROR: Could not extract URL from shortcut" -ForegroundColor Red
                    return $null
                }
            } else {
                # Read the README content from file
                try {
                    $content = Get-Content -Path $ReadmePath -Raw
                } catch {
                    Write-Host "ERROR: Could not read README file: $_" -ForegroundColor Red
                    return $null
                }
            }
        }
    }
    
    if (-not $content) {
        Write-Host "ERROR: No content retrieved from README" -ForegroundColor Red
        return $null
    }
    
    Write-Host "Successfully retrieved README content ($($content.Length) characters)" -ForegroundColor Green
    
    # Initialize result object
    $readmeData = [PSCustomObject]@{
        ReadmePath = $ReadmePath
        IsShortcut = $isShortcut
        SourceUrl = if ($isShortcut) { $targetUrl } else { $null }
        AuthorizedUsers = @()
        Administrators = @()
        AllowedSoftware = @()
        RequiredServices = @()
        ForensicsQuestions = @()
        CompetitionScenario = ""
        IsWindowsServer = $false
        ServerRoles = @()
        PasswordPolicy = @{}
        CriticalServices = @()
        RawContent = $content
    }
    
    # Parse line by line
    $lines = $content -split "`r?`n"
    $inUserSection = $false
    $inAdminSection = $false
    $inSoftwareSection = $false
    $inServiceSection = $false
    $inForensicsSection = $false
    
    foreach ($line in $lines) {
        $line = $line.Trim()
        
        # Detect Windows Server
        if ($line -match "Windows Server|Server 2019|Server 2016|Server 2012|Server 2022|Domain Controller|Active Directory") {
            $readmeData.IsWindowsServer = $true
            
            # Extract server roles
            if ($line -match "DNS") { $readmeData.ServerRoles += "DNS" }
            if ($line -match "DHCP") { $readmeData.ServerRoles += "DHCP" }
            if ($line -match "Domain Controller|Active Directory|AD DS") { $readmeData.ServerRoles += "AD DS" }
            if ($line -match "IIS|Web Server") { $readmeData.ServerRoles += "IIS" }
            if ($line -match "File Server|File Services") { $readmeData.ServerRoles += "File Server" }
            if ($line -match "Print Server") { $readmeData.ServerRoles += "Print Server" }
        }
        
        # Detect scenario description
        if ($line -match "Scenario|scenario|SCENARIO") {
            $readmeData.CompetitionScenario = $line
        }
        
        # Section detection
        if ($line -match "(?i)(authorized users|users|user accounts)") {
            $inUserSection = $true
            $inAdminSection = $false
            $inSoftwareSection = $false
            $inServiceSection = $false
            $inForensicsSection = $false
            continue
        }
        
        if ($line -match "(?i)(administrators|admin|admins)") {
            $inAdminSection = $true
            $inUserSection = $false
            $inSoftwareSection = $false
            $inServiceSection = $false
            $inForensicsSection = $false
            continue
        }
        
        if ($line -match "(?i)(allowed software|authorized software|permitted software|software|programs)") {
            $inSoftwareSection = $true
            $inUserSection = $false
            $inAdminSection = $false
            $inServiceSection = $false
            $inForensicsSection = $false
            continue
        }
        
        if ($line -match "(?i)(required services|critical services|services|service)") {
            $inServiceSection = $true
            $inUserSection = $false
            $inAdminSection = $false
            $inSoftwareSection = $false
            $inForensicsSection = $false
            continue
        }
        
        if ($line -match "(?i)(forensic|forensics question)") {
            $inForensicsSection = $true
            $inUserSection = $false
            $inAdminSection = $false
            $inSoftwareSection = $false
            $inServiceSection = $false
            continue
        }
        
        # Stop section parsing on blank lines or new sections
        if ($line -eq "" -or $line -match "^-+$|^=+$") {
            continue
        }
        
        # Extract data based on current section
        if ($inUserSection) {
            # Enhanced username extraction - handle various formats
            # Formats: "- username", "* username", "username (description)", "username: description"
            if ($line -match "^\s*[-*•]\s*([a-zA-Z0-9_\-.]+)") {
                $username = $matches[1]
                # Filter out common section headers and noise words
                if ($username -and $username.Length -ge 3 -and 
                    $username -notmatch "(?i)^(user|account|password|standard|name|login|full|first|last)$") {
                    $readmeData.AuthorizedUsers += $username
                }
            }
            # Also try format: "username - description" or "username: description"
            elseif ($line -match "^\s*([a-zA-Z0-9_\-.]+)\s*[-:]") {
                $username = $matches[1]
                if ($username -and $username.Length -ge 3 -and 
                    $username -notmatch "(?i)^(user|account|password|standard|name|login|full|first|last)$") {
                    $readmeData.AuthorizedUsers += $username
                }
            }
            # Try format: just a username on its own line
            elseif ($line -match "^([a-zA-Z0-9_\-.]+)$") {
                $username = $matches[1]
                if ($username -and $username.Length -ge 3 -and $username.Length -le 20 -and
                    $username -notmatch "(?i)^(user|account|password|standard|name|login|full|first|last|the|this|that|and|or|with)$") {
                    $readmeData.AuthorizedUsers += $username
                }
            }
        }
        
        if ($inAdminSection) {
            # Enhanced admin extraction
            if ($line -match "^\s*[-*•]\s*([a-zA-Z0-9_\-.]+)") {
                $username = $matches[1]
                if ($username -and $username.Length -ge 3 -and 
                    $username -notmatch "(?i)^(admin|administrator|account|password|user)$") {
                    $readmeData.Administrators += $username
                }
            }
            elseif ($line -match "^\s*([a-zA-Z0-9_\-.]+)\s*[-:]") {
                $username = $matches[1]
                if ($username -and $username.Length -ge 3 -and 
                    $username -notmatch "(?i)^(admin|administrator|account|password|user)$") {
                    $readmeData.Administrators += $username
                }
            }
            elseif ($line -match "^([a-zA-Z0-9_\-.]+)$") {
                $username = $matches[1]
                if ($username -and $username.Length -ge 3 -and $username.Length -le 20 -and
                    $username -notmatch "(?i)^(admin|administrator|account|password|user|the|this|that|and|or|with)$") {
                    $readmeData.Administrators += $username
                }
            }
        }
        
        if ($inSoftwareSection) {
            # Enhanced software extraction - handle various formats
            if ($line -match "^\s*[-*•]\s*(.+?)(?:\s*\(|:|$)") {
                $software = $matches[1].Trim()
                if ($software -and $software.Length -gt 2 -and $software.Length -le 100 -and 
                    $software -notmatch "(?i)^(software|program|application|installed|allowed|authorized|permitted)$") {
                    $readmeData.AllowedSoftware += $software
                }
            }
            elseif ($line -match "^(.+?)(?:\s*-\s*|\s*:\s*)") {
                $software = $matches[1].Trim()
                if ($software -and $software.Length -gt 2 -and $software.Length -le 100 -and 
                    $software -notmatch "(?i)^(software|program|application|installed|allowed|authorized|permitted)$") {
                    $readmeData.AllowedSoftware += $software
                }
            }
        }
        
        if ($inServiceSection) {
            # Enhanced service extraction
            if ($line -match "^\s*[-*•]\s*(.+?)(?:\s*\(|:|$)") {
                $service = $matches[1].Trim()
                if ($service -and $service.Length -gt 2 -and $service.Length -le 100 -and 
                    $service -notmatch "(?i)^(service|required|critical|running|started)$") {
                    $readmeData.RequiredServices += $service
                    $readmeData.CriticalServices += $service
                }
            }
            elseif ($line -match "^(.+?)(?:\s*-\s*|\s*:\s*)") {
                $service = $matches[1].Trim()
                if ($service -and $service.Length -gt 2 -and $service.Length -le 100 -and 
                    $service -notmatch "(?i)^(service|required|critical|running|started)$") {
                    $readmeData.RequiredServices += $service
                    $readmeData.CriticalServices += $service
                }
            }
        }
        
        if ($inForensicsSection) {
            # Capture forensics questions
            if ($line -match "^\s*[-*•]?\s*(.+)") {
                $question = $matches[1].Trim()
                if ($question -and $question.Length -gt 5) {
                    $readmeData.ForensicsQuestions += $question
                }
            }
        }
        
        # Password policy detection
        if ($line -match "password.{0,20}(\d+).{0,20}character|(\d+).{0,20}character.{0,20}password") {
            $readmeData.PasswordPolicy["MinLength"] = $matches[1]
        }
        if ($line -match "password.{0,20}complexity|complex.{0,20}password") {
            $readmeData.PasswordPolicy["Complexity"] = $true
        }
    }
    
    # Remove duplicates
    $readmeData.AuthorizedUsers = $readmeData.AuthorizedUsers | Select-Object -Unique
    $readmeData.Administrators = $readmeData.Administrators | Select-Object -Unique
    $readmeData.AllowedSoftware = $readmeData.AllowedSoftware | Select-Object -Unique
    $readmeData.RequiredServices = $readmeData.RequiredServices | Select-Object -Unique
    $readmeData.ServerRoles = $readmeData.ServerRoles | Select-Object -Unique
    
    return $readmeData
}

function Export-ReadmeData {
    <#
    .SYNOPSIS
        Exports parsed README data to a JSON file for use by other scripts
    #>
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$ReadmeData,
        
        [string]$OutputPath = ".\ReadmeData.json"
    )
    
    try {
        $ReadmeData | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "README data exported to: $OutputPath" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "ERROR: Failed to export README data: $_" -ForegroundColor Red
        return $false
    }
}

function Import-ReadmeData {
    <#
    .SYNOPSIS
        Imports previously parsed README data from JSON file
    #>
    param(
        [string]$InputPath = ".\ReadmeData.json"
    )
    
    if (-not (Test-Path $InputPath)) {
        return $null
    }
    
    try {
        $data = Get-Content -Path $InputPath -Raw | ConvertFrom-Json
        return $data
    } catch {
        Write-Host "ERROR: Failed to import README data: $_" -ForegroundColor Red
        return $null
    }
}

function Show-ReadmeData {
    <#
    .SYNOPSIS
        Displays parsed README data in a readable format
    #>
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$ReadmeData
    )
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  Competition README Analysis" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    Write-Host "`nREADME File: " -NoNewline
    Write-Host $ReadmeData.ReadmePath -ForegroundColor Yellow
    
    if ($ReadmeData.IsShortcut -and $ReadmeData.SourceUrl) {
        Write-Host "Source Type: " -NoNewline
        Write-Host "Web Shortcut (.lnk)" -ForegroundColor Cyan
        Write-Host "Source URL: " -NoNewline
        Write-Host $ReadmeData.SourceUrl -ForegroundColor Yellow
    }
    
    if ($ReadmeData.CompetitionScenario) {
        Write-Host "`nScenario: " -NoNewline
        Write-Host $ReadmeData.CompetitionScenario -ForegroundColor Yellow
    }
    
    Write-Host "`nSystem Type: " -NoNewline
    if ($ReadmeData.IsWindowsServer) {
        Write-Host "Windows Server" -ForegroundColor Green
        if ($ReadmeData.ServerRoles.Count -gt 0) {
            Write-Host "Server Roles: " -NoNewline
            Write-Host ($ReadmeData.ServerRoles -join ", ") -ForegroundColor Green
        }
    } else {
        Write-Host "Windows Desktop" -ForegroundColor Green
    }
    
    Write-Host "`nAuthorized Users: " -NoNewline
    if ($ReadmeData.AuthorizedUsers.Count -gt 0) {
        Write-Host $ReadmeData.AuthorizedUsers.Count -ForegroundColor Green
        foreach ($user in $ReadmeData.AuthorizedUsers) {
            Write-Host "  - $user" -ForegroundColor Gray
        }
    } else {
        Write-Host "None specified" -ForegroundColor Yellow
    }
    
    Write-Host "`nAdministrators: " -NoNewline
    if ($ReadmeData.Administrators.Count -gt 0) {
        Write-Host $ReadmeData.Administrators.Count -ForegroundColor Green
        foreach ($admin in $ReadmeData.Administrators) {
            Write-Host "  - $admin" -ForegroundColor Gray
        }
    } else {
        Write-Host "None specified" -ForegroundColor Yellow
    }
    
    Write-Host "`nAllowed Software: " -NoNewline
    if ($ReadmeData.AllowedSoftware.Count -gt 0) {
        Write-Host $ReadmeData.AllowedSoftware.Count -ForegroundColor Green
        foreach ($software in $ReadmeData.AllowedSoftware) {
            Write-Host "  - $software" -ForegroundColor Gray
        }
    } else {
        Write-Host "None specified" -ForegroundColor Yellow
    }
    
    Write-Host "`nRequired Services: " -NoNewline
    if ($ReadmeData.RequiredServices.Count -gt 0) {
        Write-Host $ReadmeData.RequiredServices.Count -ForegroundColor Green
        foreach ($service in $ReadmeData.RequiredServices) {
            Write-Host "  - $service" -ForegroundColor Gray
        }
    } else {
        Write-Host "None specified" -ForegroundColor Yellow
    }
    
    Write-Host "`nForensics Questions: " -NoNewline
    if ($ReadmeData.ForensicsQuestions.Count -gt 0) {
        Write-Host $ReadmeData.ForensicsQuestions.Count -ForegroundColor Green
        foreach ($question in $ReadmeData.ForensicsQuestions) {
            Write-Host "  - $question" -ForegroundColor Gray
        }
    } else {
        Write-Host "None found" -ForegroundColor Yellow
    }
    
    Write-Host "`n========================================`n" -ForegroundColor Cyan
}

# Export functions for use in other scripts
Export-ModuleMember -Function Find-CompetitionReadme, Parse-CompetitionReadme, Export-ReadmeData, Import-ReadmeData, Show-ReadmeData
