#Requires -Version 5.1
<#
.SYNOPSIS
    Check that the Stop Slop skill is installed for OpenCode.

.PARAMETER SkillDir
    OpenCode skills root. Defaults to $env:OPENCODE_SKILLS_DIR, or
    ~/.config/opencode/skills.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\verify.ps1
#>
[CmdletBinding()]
param(
    [string]$SkillDir
)

$ErrorActionPreference = "Stop"

$Name = "stop-slop"

if (-not $SkillDir) {
    if ($env:OPENCODE_SKILLS_DIR) {
        $SkillDir = $env:OPENCODE_SKILLS_DIR
    }
    else {
        $HomeDir = if ($HOME) { $HOME } elseif ($env:USERPROFILE) { $env:USERPROFILE } else { $null }
        if (-not $HomeDir) {
            Write-Host "FAIL  Could not find your home directory. Pass -SkillDir explicitly." -ForegroundColor Red
            exit 1
        }
        $SkillDir = Join-Path $HomeDir ".config\opencode\skills"
    }
}

$Target = Join-Path $SkillDir $Name

if (-not (Test-Path -LiteralPath $Target)) {
    Write-Host "FAIL  $Name is not installed at $Target" -ForegroundColor Red
    Write-Host "      Run install.ps1 first." -ForegroundColor Yellow
    exit 1
}

$Required = @(
    "SKILL.md",
    "references\phrases.md",
    "references\structures.md",
    "references\examples.md",
    "LICENSE"
)

$Missing = @()
foreach ($RelativePath in $Required) {
    if (-not (Test-Path -LiteralPath (Join-Path $Target $RelativePath))) {
        $Missing += $RelativePath
    }
}

if ($Missing.Count -gt 0) {
    Write-Host "FAIL  The installation is incomplete. Missing:" -ForegroundColor Red
    $Missing | ForEach-Object { Write-Host "      - $_" }
    Write-Host "      Re-run install.ps1 -Force." -ForegroundColor Yellow
    exit 1
}

$SkillText = Get-Content -LiteralPath (Join-Path $Target "SKILL.md") -Raw
if ($SkillText -notmatch "(?m)^name:[ \t]*$([regex]::Escape($Name))[ \t]*$") {
    Write-Host "FAIL  SKILL.md has an unexpected 'name' field." -ForegroundColor Red
    exit 1
}
if ($SkillText -notmatch "(?m)^description:[ \t]*\S") {
    Write-Host "FAIL  SKILL.md has no description, so OpenCode will not list the skill." -ForegroundColor Red
    exit 1
}

$FileCount = (Get-ChildItem -LiteralPath $Target -Recurse -File).Count
Write-Host "OK  $Name is installed at $Target ($FileCount files)." -ForegroundColor Green
