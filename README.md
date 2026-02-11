# CyberPatriot Automated Security Hardening Tool

This repository contains an automated PowerShell script for CyberPatriot competitions that performs common security hardening tasks on Windows systems.

## 🚀 Quick Start

### Prerequisites
- Windows 10/11 or Windows Server
- PowerShell 5.1 or higher
- Administrator privileges

### Running the Automation Suite

**EASIEST METHOD - Use the Master Control Script:**

1. **Download or clone this repository**

2. **Open PowerShell as Administrator**
   - Right-click on PowerShell and select "Run as Administrator"

3. **Navigate to the repository directory**
   ```powershell
   cd path\to\Windows-Stuff
   ```

4. **Run the master control script**
   ```powershell
   .\Run-CyberPatriot.ps1
   ```

5. **Follow the interactive menu**
   - **First:** Analyze README (extracts competition requirements)
   - Choose Quick Audit for a fast security overview
   - Run Security Hardening to apply automated fixes
   - Run Server Hardening if on Windows Server
   - Run File Auditor to find unauthorized files
   - Run User Auditor to review accounts
   - **Last:** Run Windows Update (option W)
   - Or select "R" to run all tasks in sequence!

**ALTERNATIVE - Run individual scripts:**
   ```powershell
   .\AnalyzeReadme.ps1         # Parse competition README (do this first!)
   .\CyberPatriot-Auto.ps1     # Main security hardening with GUI
   .\ServerHardening.ps1       # Windows Server-specific hardening
   .\FileAuditor.ps1           # Find unauthorized files/software
   .\UserAuditor.ps1           # Review user accounts
   ```

## 🆕 NEW: Smart README Parser

The suite now automatically reads the competition README to avoid false positives!

**Supports Multiple Input Methods:**
- Text files (.txt, .md)
- **Desktop shortcuts (.lnk)** that point to websites
- Internet shortcuts (.url)
- **Smart clipboard paste** (recommended for manual input)
- Line-by-line manual paste as fallback
- **Automatic HTML cleanup** when pasting from web pages

**Advanced Features:**
- **Intelligent clipboard support**: Copy README from browser, paste directly from clipboard
- **HTML auto-detection and cleanup**: Automatically removes HTML tags and formats content
- **Enhanced pattern matching**: Smarter extraction of users, software, and services
- **Content validation**: Preview and confirm pasted content before processing
- **Multiple format support**: Handles plain text, markdown, HTML, and mixed formats

**Extracts:**
- Authorized users and administrators
- Allowed software/programs
- Required services (won't disable these!)
- Server roles (DNS, DHCP, IIS, AD DS)
- Forensics question indicators
- Password policy requirements

**How to use:**
1. Place README file/shortcut on Desktop (or it will auto-find it)
2. Run `.\AnalyzeReadme.ps1` first (or use the Master Control menu)
3. If download fails:
   - **Option 1 (Recommended)**: Copy README in browser (Ctrl+A, Ctrl+C), choose 'C' for clipboard paste
   - **Option 2**: Choose 'M' for manual line-by-line paste
4. The parser will automatically clean HTML and validate the content
5. Other scripts automatically use the parsed data

## 📋 Features

The automated script can perform the following security tasks:

### 🔐 Security Hardening
- **Enable Windows Firewall** - Turns on firewall for all network profiles
- **Disable Guest Account** - Disables the built-in Guest account
- **Disable Administrator Account** - Disables the built-in Administrator account (not your current user)
- **Configure Password Policies** - Sets secure password requirements:
  - Minimum password length: 10 characters
  - Password complexity: Enabled
  - Password history: 24 passwords
  - Maximum password age: 90 days
  - Minimum password age: 1 day
  - Account lockout threshold: 10 attempts
  - Account lockout duration: 30 minutes

### 🛡️ Service Management
- **Disable Insecure Services** - Stops and disables:
  - Remote Desktop (RDP)
  - FTP Service
  - Remote Registry
  - SSDP Discovery
  - UPnP Device Host
  - WWW Publishing Service
  - SMTP Service

### 🔒 Network Security
- **Block Vulnerable Ports** - Creates firewall rules to block:
  - RDP (3389)
  - SSH (22)
  - Telnet (23)
  - SNMP (161, 162)
  - LDAP (389)
  - FTP (20, 21)

### 🔍 Auditing & Monitoring
- **Configure Audit Policies** - Enables logging for:
  - Account Logon events
  - Account Management
  - Logon/Logoff events
  - Policy Changes
  - System events

### 🛠️ Additional Features
- **Enable Automatic Updates** - Configures Windows to automatically update
- **Enable Windows Security** - Activates Windows Defender real-time protection
- **Run Quick Scan** - Starts a Windows Defender malware scan
- **Enable Secure Logon** - Requires Ctrl+Alt+Del before login
- **Hide Last Username** - Prevents displaying the last logged-in username

## 📊 Logging

All actions are logged to a timestamped log file:
- Log files are created in the same directory as the script
- Format: `CyberPatrior-AutoLog-YYYYMMDD-HHMMSS.txt`
- Click "View Log" button in the GUI to open the log file
- Logs include timestamps, action types, and detailed results

## 📁 Repository Structure

```
Windows-Stuff/
├── START-HERE.bat             # 🚀 Double-click to start (batch launcher)
├── Run-CyberPatriot.ps1       # ⭐ MASTER CONTROL SCRIPT - Main menu
├── AnalyzeReadme.ps1          # 🆕 README parser (handles .lnk shortcuts!)
├── ReadmeParser.ps1           # 🆕 README parsing module
├── CyberPatriot-Auto.ps1      # Security hardening automation with GUI
├── ServerHardening.ps1        # 🆕 Windows Server-specific hardening
├── MalwareHunter.ps1          # 🦠 Enhanced malware detection
├── FileAuditor.ps1            # Scans for unauthorized files (uses README data)
├── UserAuditor.ps1            # Reviews user accounts (uses README data)
├── README.md                  # This file
├── QUICK_START.md             # Quick reference guide
├── checklist/                 # Reference materials
│   ├── windows-checklist.md   # Manual checklist
│   └── *.pdf                  # Answer keys and guides
└── scripts/                   # Additional utility scripts
```

## 🎮 Master Control Script (Run-CyberPatriot.ps1)

The **Run-CyberPatriot.ps1** script is your main entry point with an enhanced, user-friendly interface!

**New Features:**
- **Visual workflow guide**: Clear step-by-step instructions with progress indicators
- **One-click automation**: Press [R] to run all recommended tasks in sequence
- **Smart progress tracking**: Visual separators and completion confirmations
- **Helpful descriptions**: Each tool shows what it does before running
- **Error handling**: Clear error messages with troubleshooting guidance
- **Estimated time**: Shows expected duration for "Run All" sequence

**Features:**
- Interactive menu for easy navigation
- README analyzer (first step!)
- Quick audit to assess current security state
- Orchestrated execution of all tools in the recommended order
- Windows Update launcher (run last!)
- Easy access to logs, checklists, and documentation

Simply run: `.\Run-CyberPatriot.ps1` and follow the menu!

## 🔧 Individual Scripts

### AnalyzeReadme.ps1 (NEW - Run First!)
Parses the competition README to extract requirements:
```powershell
.\AnalyzeReadme.ps1
```
- **Handles .lnk shortcuts** to websites (CyberPatriot standard!)
- **Downloads web content** automatically
- **Manual paste fallback** if download fails
- Extracts: users, software, services, server roles
- Exports to ReadmeData.json for other scripts
- **Run this first** to avoid false positives!

### ServerHardening.ps1 (NEW - Windows Server Only)
Server-specific security hardening:
```powershell
.\ServerHardening.ps1
```
- Detects Windows Server automatically
- Active Directory hardening (Kerberos, SMBv1)
- DNS Server security
- DHCP Server security
- IIS hardening
- File Server SMB encryption
- Enhanced auditing
- **Uses README data** to protect required services

### CyberPatriot-Auto.ps1 (Main Automation)
The core security hardening script with GUI interface:
```powershell
.\CyberPatriot-Auto.ps1
```
- Features all automated security fixes (firewall, passwords, services, etc.)
- **Uses README data** to avoid disabling required services
- **Windows Update reminder** at completion

### FileAuditor.ps1
Scans for unauthorized files and software that should be removed:
```powershell
.\FileAuditor.ps1
```
- Detects unauthorized software (BitTorrent, Wireshark, CCleaner, etc.)
- **Filters allowed software** from README
- Finds media files (music, videos, games)
- Lists suspicious running processes
- Reviews startup items
- Generates detailed audit log

### UserAuditor.ps1
Reviews user accounts, groups, and permissions:
```powershell
.\UserAuditor.ps1
```
- Lists all user accounts with status
- **Checks against authorized users** from README
- Shows group memberships
- Identifies users with admin privileges
- **NEW: Verifies admin access** - checks if right users are admins
- **NEW: Password strength analysis** - checks for weak/old passwords
- Reviews password policies
- Opens interactive GUI for user management
- Generates detailed audit log

**Admin Verification:**
- Compares actual admins vs authorized admins from README
- Flags unauthorized admins (shouldn't have access)
- Flags missing admins (should have access but don't)

**Password Strength Checks:**
- Identifies users without password requirements
- Finds expired passwords
- Detects passwords that never expire
- Flags old passwords (>60 or >90 days)
- Checks password configuration compliance

### MalwareHunter.ps1 ⚠️ Malware was a BIG problem last season!
Comprehensive malware detection and removal tool:
```powershell
.\MalwareHunter.ps1
```
- **Updates Windows Defender malware definitions**
- Scans for malicious processes currently running
- Finds suspicious files in temp/download folders
- Checks startup items and scheduled tasks for malware
- Analyzes HOSTS file for malicious entries
- Offers to run full system scan (30+ minutes)
- **USE THIS EARLY** - Malware removal can give major points!

## ⚠️ CRITICAL SAFETY INFORMATION

### 🆕 README-Aware Filtering
**The scripts now read the competition README to avoid false positives!**

**What this means:**
- Users listed in README won't be flagged as unauthorized
- Software listed in README won't be flagged for removal
- Services listed in README won't be disabled
- Server roles from README guide which hardening to apply

**How it works:**
1. Run `AnalyzeReadme.ps1` first
2. It parses the README (even if it's a .lnk shortcut!)
3. Creates ReadmeData.json with requirements
4. Other scripts automatically load and use this data

**If README is a .lnk shortcut (common in CyberPatriot):**
- Script automatically extracts the URL
- Downloads the web page content
- Parses it for requirements
- If download fails, you can paste content manually!

### 🛡️ Forensics Questions Protection
**IMPORTANT:** Some files on the competition system are needed for forensics questions!
- The scripts automatically exclude files/folders with "CyberPatriot", "Forensic", or "README" in the name
- **FileAuditor.ps1 ONLY REPORTS findings - it does NOT delete anything**
- **ALWAYS manually review files before deleting**
- Files needed for forensics points include:
  - Images with hidden data
  - Files with specific hashes
  - Encrypted or encoded files
  - README files with competition instructions

### What These Scripts Do NOT Do
- **Does NOT change your current user's password** - You must manage passwords manually
- **Does NOT delete ANY files** - Scripts only report findings; you delete manually
- **Does NOT delete unauthorized software automatically** - It will detect but requires manual removal
- **Does NOT interfere with CyberPatriot competition files** - These are automatically excluded
- **Does NOT modify registry beyond documented security settings**
- **Does NOT answer forensic questions** - These require manual analysis

### Before Running ANY Script
1. ✅ **Read the competition README file thoroughly**
2. ✅ **Write down your password on another computer** - Critical!
3. ✅ **Complete all forensics questions FIRST** - Don't risk losing points
4. ✅ **Review what each script does** - Understand the changes being made

### Manual Tasks Still Required

Based on the checklist, you should still manually:

1. ~~**Read the competition README file thoroughly**~~ (Do this FIRST, before scripts!)
2. ~~**Write down your password on another computer**~~ (Do this FIRST!)
3. ~~**Answer forensic questions**~~ (Do this BEFORE running FileAuditor!)
4. **Review user accounts** - Verify which users should exist per README
5. **Review installed software** - Decide what should be removed per README
6. **Check for media files** - Use FileAuditor, then MANUALLY delete after review
7. **Review browser settings** - Configure Firefox/Chrome security
8. **Update browsers** - Firefox, Chrome, Edge
9. **Review shared folders** - Check for unauthorized shares
10. **Run final system updates** - After all other changes

## 🎯 Best Practice Workflow

1. **Before the Competition**
   - Familiarize yourself with the script
   - Read through the checklist folder materials
   - Practice on a test system

2. **During the Competition**
   - Read the README file first (always!)
   - Write down your password
   - Answer forensic questions
   - **Run the automation script:** `.\CyberPatriot-Auto.ps1`
   - **Run the file auditor:** `.\FileAuditor.ps1` (to find files to delete)
   - **Run the user auditor:** `.\UserAuditor.ps1` (to review accounts)
   - Delete unauthorized files and software based on audit results
   - Perform remaining manual tasks from the checklist
   - Review and verify all changes
   - Run system updates last

3. **After Running the Script**
   - Review the log file for any failures
   - Fix any issues that couldn't be automated
   - Verify security settings are applied
   - Test system functionality

## 📚 Additional Resources

- **Checklist Folder**: Contains detailed manual checklists and answer keys from previous competitions
- **Scripts Folder**: Contains additional utility scripts for specific tasks

## 🔧 Troubleshooting

**Script won't run:**
- Ensure you're running PowerShell as Administrator
- Check PowerShell execution policy: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process`

**GUI doesn't appear:**
- Verify .NET Framework is installed
- Check if Windows Forms assemblies are available

**Tasks fail:**
- Review the log file for specific error messages
- Some features may not be available on all Windows versions
- Ensure the system has internet connectivity for updates

## 📝 License

This is a tool for educational purposes for CyberPatriot competitions.

## 🤝 Contributing

Feel free to submit issues or pull requests to improve the automation script.

---

**Remember**: This tool is meant to assist, not replace, your security knowledge. Always understand what each task does before running it!
