#Requires -Version 5.1
<#
.SYNOPSIS
    Install the free Stop Slop skill for OpenCode.

.DESCRIPTION
    Downloads the skill from the official hardikpandya/stop-slop repository
    and copies it to the OpenCode global skills directory, so OpenCode discovers
    it automatically. Nothing is vendored or re-hosted by this project.

.PARAMETER SkillDir
    OpenCode skills root. Defaults to $env:OPENCODE_SKILLS_DIR, or
    ~/.config/opencode/skills.

.PARAMETER Ref
    Branch, tag, or commit of the upstream repository. Defaults to "main".

.PARAMETER Force
    Replace an existing installation. Without it, the installer leaves the
    current copy untouched.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\install.ps1

.EXAMPLE
    .\install.ps1 -Force -Ref main
#>
[CmdletBinding()]
param(
    [string]$SkillDir,
    [string]$Ref = "main",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

if ($env:STOP_SLOP_REF -and -not $PSBoundParameters.ContainsKey("Ref")) {
    $Ref = $env:STOP_SLOP_REF
}
if ($env:STOP_SLOP_FORCE -eq "1") {
    $Force = $true
}

$Repo = "hardikpandya/stop-slop"
$Name = "stop-slop"

function Write-Step([string]$Message) {
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok([string]$Message) {
    Write-Host "OK  $Message" -ForegroundColor Green
}

function Write-Warn([string]$Message) {
    Write-Host "!!  $Message" -ForegroundColor Yellow
}

function Expand-TarGz([string]$Archive, [string]$Destination) {
    # Minimal tar extractor for the upstream archive. It keeps the Windows
    # installer dependency-free on PowerShell 5.1 (no tar.exe required).
    Add-Type -AssemblyName System.IO.Compression

    $TarPath = Join-Path $Destination "archive.tar"
    $Input = [System.IO.File]::OpenRead($Archive)
    try {
        $Gzip = New-Object System.IO.Compression.GZipStream($Input, [System.IO.Compression.CompressionMode]::Decompress)
        try {
            $Output = [System.IO.File]::Create($TarPath)
            try {
                $Gzip.CopyTo($Output)
            }
            finally {
                $Output.Dispose()
            }
        }
        finally {
            $Gzip.Dispose()
        }
    }
    finally {
        $Input.Dispose()
    }

    $Bytes = [System.IO.File]::ReadAllBytes($TarPath)
    $Position = 0
    $LongName = $null
    $PaxPath = $null

    while ($Position + 512 -le $Bytes.Length) {
        $Header = New-Object byte[] 512
        [Array]::Copy($Bytes, $Position, $Header, 0, 512)
        $Position += 512

        $AllZero = $true
        foreach ($Byte in $Header) {
            if ($Byte -ne 0) {
                $AllZero = $false
                break
            }
        }
        if ($AllZero) {
            break
        }

        $RawName = [System.Text.Encoding]::UTF8.GetString($Header, 0, 100).TrimEnd([char]0)
        $Prefix = [System.Text.Encoding]::UTF8.GetString($Header, 345, 155).TrimEnd([char]0)
        $SizeText = [System.Text.Encoding]::ASCII.GetString($Header, 124, 12).Trim([char]0).Trim()
        $Size = if ($SizeText) { [Convert]::ToInt64($SizeText, 8) } else { 0 }
        $Type = [char]$Header[156]
        $DataStart = $Position
        $Padded = [int]([Math]::Ceiling($Size / 512.0) * 512)

        if ($Type -eq "x" -or $Type -eq "g") {
            if ($Type -eq "x" -and $Size -gt 0) {
                $PaxText = [System.Text.Encoding]::UTF8.GetString($Bytes, $DataStart, [int]$Size)
                foreach ($Line in ($PaxText -split "`n")) {
                    if ($Line -match "^\d+ path=(.*)$") {
                        $PaxPath = $Matches[1]
                    }
                }
            }
            $Position = $DataStart + $Padded
            continue
        }

        if ($Type -eq "L") {
            $LongName = [System.Text.Encoding]::UTF8.GetString($Bytes, $DataStart, [int]$Size).TrimEnd([char]0)
            $Position = $DataStart + $Padded
            continue
        }

        $EntryName = if ($PaxPath) {
            $PaxPath
        }
        elseif ($LongName) {
            $LongName
        }
        elseif ($Prefix) {
            "$Prefix/$RawName"
        }
        else {
            $RawName
        }
        $PaxPath = $null
        $LongName = $null
        $Position = $DataStart + $Padded

        $Relative = $EntryName.Replace("\", "/").TrimStart("/")
        if (-not $Relative) {
            continue
        }
        if ($Relative -match "(^|/)\.\.(/|$)" -or $Relative -match "^[A-Za-z]:") {
            continue
        }

        $OutPath = Join-Path $Destination $Relative.Replace("/", [System.IO.Path]::DirectorySeparatorChar)

        if ($Type -eq "5" -or $EntryName.EndsWith("/")) {
            New-Item -ItemType Directory -Path $OutPath -Force | Out-Null
            continue
        }

        if ($Type -eq "0" -or $Type -eq "7" -or $Type -eq [char]0) {
            $Parent = Split-Path -Parent $OutPath
            if ($Parent) {
                New-Item -ItemType Directory -Path $Parent -Force | Out-Null
            }
            $FileBytes = New-Object byte[] ([int]$Size)
            if ($Size -gt 0) {
                [Array]::Copy($Bytes, $DataStart, $FileBytes, 0, [int]$Size)
            }
            [System.IO.File]::WriteAllBytes($OutPath, $FileBytes)
        }
    }

    Remove-Item -LiteralPath $TarPath -Force -ErrorAction SilentlyContinue
}

if (-not $SkillDir) {
    if ($env:OPENCODE_SKILLS_DIR) {
        $SkillDir = $env:OPENCODE_SKILLS_DIR
    }
    else {
        $HomeDir = if ($HOME) { $HOME } elseif ($env:USERPROFILE) { $env:USERPROFILE } else { $null }
        if (-not $HomeDir) {
            throw "Could not find your home directory. Pass -SkillDir explicitly."
        }
        $SkillDir = Join-Path $HomeDir ".config\opencode\skills"
    }
}

$Target = Join-Path $SkillDir $Name

if ((Split-Path -Leaf $Target) -ne $Name) {
    throw "Refusing to install to an unexpected path: $Target"
}

$AlreadyInstalled = $false

if (Test-Path -LiteralPath $Target) {
    if (-not $Force) {
        Write-Warn "$Name is already installed at:"
        Write-Host "    $Target"
        Write-Host "    Re-run with -Force to update it."
        $AlreadyInstalled = $true
    }
    else {
        Write-Step "Removing the existing installation"
        Remove-Item -LiteralPath $Target -Recurse -Force
    }
}

$TempDir = $null
if (-not $AlreadyInstalled) {
    $TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("stop-slop-" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $TempDir | Out-Null
}

try {
    if ($AlreadyInstalled) {
        return
    }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }
    catch {
        # PowerShell 7 / .NET Core does not need (and may reject) this setting.
    }

    $Url = "https://codeload.github.com/$Repo/tar.gz/$Ref"
    $Archive = Join-Path $TempDir "skill.tar.gz"

    Write-Step "Downloading $Url"
    $OldProgress = $ProgressPreference
    $ProgressPreference = "SilentlyContinue"
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Archive -UseBasicParsing
    }
    finally {
        $ProgressPreference = $OldProgress
    }

    Write-Step "Extracting"
    Expand-TarGz -Archive $Archive -Destination $TempDir

    $SkillMd = Get-ChildItem -LiteralPath $TempDir -Recurse -File -Filter "SKILL.md" |
        Where-Object {
            (Get-Content -LiteralPath $_.FullName -Raw) -match "(?m)^name:[ \t]*$([regex]::Escape($Name))[ \t]*$"
        } |
        Select-Object -First 1

    if (-not $SkillMd) {
        throw "Could not find stop-slop/SKILL.md in the downloaded archive. The upstream layout may have changed."
    }

    $SkillText = Get-Content -LiteralPath $SkillMd.FullName -Raw
    if ($SkillText -notmatch "(?m)^description:[ \t]*\S") {
        throw "SKILL.md has no description, so OpenCode will not list the skill."
    }

    $Source = $SkillMd.Directory.FullName
    $References = Join-Path $Source "references"
    $License = Join-Path $Source "LICENSE"

    if (-not (Test-Path -LiteralPath $References)) {
        throw "The upstream archive has no references/ directory. The upstream layout may have changed."
    }
    if (-not (Test-Path -LiteralPath $License)) {
        throw "The upstream archive has no LICENSE file. The upstream layout may have changed."
    }

    Write-Step "Installing to $Target"
    New-Item -ItemType Directory -Path $SkillDir -Force | Out-Null
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $Source "SKILL.md") -Destination $Target -Force
    Copy-Item -LiteralPath $References -Destination $Target -Recurse -Force
    Copy-Item -LiteralPath $License -Destination $Target -Force

    $Required = @(
        "SKILL.md",
        "references\phrases.md",
        "references\structures.md",
        "references\examples.md",
        "LICENSE"
    )
    foreach ($RelativePath in $Required) {
        if (-not (Test-Path -LiteralPath (Join-Path $Target $RelativePath))) {
            throw "Installation is incomplete: missing $RelativePath."
        }
    }

    $FileCount = (Get-ChildItem -LiteralPath $Target -Recurse -File).Count
    Write-Ok "Installed $FileCount files to $Target"
}
finally {
    if ($TempDir) {
        Remove-Item -LiteralPath $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "Start a new OpenCode session and ask it to draft, edit or review prose." -ForegroundColor Green
Write-Host "The skill is picked up automatically. Examples:"
Write-Host '  - "Draft a launch note for my note-taking app without the usual AI tells."'
Write-Host '  - "Edit this paragraph: cut the filler, the passive voice and the em dashes."'
Write-Host '  - "Review this README and flag every predictable AI phrase."'
Write-Host ""
Write-Host "Source and license: https://github.com/$Repo"
