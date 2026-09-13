# Native Windows Dotfiles installer. Dotfiles owns terminal tools/config;
# ShipGlows owns developer provisioning, AI agents, skills, MCP and Doppler.
[CmdletBinding()]
param(
    [string]$RepoUrl = 'https://github.com/commandglows/dotfiles.git',
    [string]$Branch = 'master',
    [string]$DotfilesDir = (Join-Path $env:USERPROFILE '.dotfiles'),
    [string]$StateDir = (Join-Path $env:LOCALAPPDATA 'dotfiles\state'),
    [switch]$DryRun, [switch]$Check, [switch]$Update, [switch]$Uninstall,
    [string[]]$Only,
    [switch]$ConfigureWezTerm, [switch]$SkipWezTerm,
    [switch]$ConfigureTools, [switch]$SkipTools,
    [switch]$InstallYaziPlugins
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$script:JournalPath = Join-Path $StateDir 'journal.tsv'
$script:SourceRoot = $PSScriptRoot
$script:CodexAcpPackage = '@zed-industries/codex-acp@0.16.0'

function Write-Info([string]$Message) { Write-Host "[Dotfiles] $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message) { Write-Host "[Dotfiles] $Message" -ForegroundColor Green }
function Write-Plan([string]$Message) { Write-Host "[Dotfiles] DRY-RUN: $Message" -ForegroundColor Yellow }
function Get-App([string]$Name) { Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1 }

function Get-NodePackageManager {
    foreach ($name in @('pnpm.cmd','pnpm.exe','npm.cmd','npm.exe')) {
        $manager = Get-App $name
        if ($manager) { return $manager.Source }
    }
    $null
}

function Get-CodexAcpPlatformPackage {
    $architecture = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
    if ($architecture -notin @('x64','arm64')) { throw "Codex ACP does not provide a supported Windows runtime for architecture '$architecture'." }
    "codex-acp-win32-$architecture"
}

function Get-NodeGlobalRoot([string]$Manager) {
    if (-not $Manager) { return $null }
    $output = @(& $Manager root --global 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not $output) { return $null }
    $candidate = ($output -join "`n").Trim()
    if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Container)) { [IO.Path]::GetFullPath($candidate) }
}

function Get-NodeGlobalBin([string]$Manager) {
    if (-not $Manager -or -not [IO.Path]::GetFileName($Manager).ToLowerInvariant().StartsWith('pnpm')) { return $null }
    $output = @(& $Manager bin --global 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not $output) { return $null }
    $candidate = ($output -join "`n").Trim()
    if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Container)) { [IO.Path]::GetFullPath($candidate) }
}

function Find-CodexAcpWrapper([string]$Manager = '') {
    $globalBin = Get-NodeGlobalBin $Manager
    if ($globalBin) {
        $candidate = Join-Path $globalBin 'codex-acp.CMD'
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return [IO.Path]::GetFullPath($candidate) }
    }
    if ($env:APPDATA) {
        $candidate = Join-Path $env:APPDATA 'npm\codex-acp.CMD'
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return [IO.Path]::GetFullPath($candidate) }
    }
    if ($env:LOCALAPPDATA) {
        $candidate = Join-Path $env:LOCALAPPDATA 'pnpm\bin\codex-acp.CMD'
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return [IO.Path]::GetFullPath($candidate) }
    }
    $wrapper = Get-App 'codex-acp.cmd'
    if ($wrapper) { return $wrapper.Source }
    $null
}

function Find-CodexAcpNativeBinary([string]$Manager = '') {
    $platformPackage = Get-CodexAcpPlatformPackage
    $roots = [Collections.Generic.List[string]]::new()
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    function Add-Root([string]$Path) {
        if ($Path -and (Test-Path -LiteralPath $Path -PathType Container)) {
            $full = [IO.Path]::GetFullPath($Path)
            if ($seen.Add($full)) { $roots.Add($full) }
        }
    }

    $managerName = if ($Manager) { [IO.Path]::GetFileName($Manager).ToLowerInvariant() } else { '' }
    $globalRoot = Get-NodeGlobalRoot $Manager
    if ($globalRoot -and $managerName.StartsWith('pnpm')) {
        foreach ($instanceRoot in @(Get-ChildItem -LiteralPath $globalRoot -Directory -ErrorAction SilentlyContinue)) {
            Add-Root (Join-Path $instanceRoot.FullName 'node_modules')
        }
    } else {
        Add-Root $globalRoot
    }
    if ($env:APPDATA) { Add-Root (Join-Path $env:APPDATA 'npm\node_modules') }
    foreach ($pnpmRoot in @(
        $(if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA 'pnpm\global' }),
        $(if ($env:PNPM_HOME) { Join-Path $env:PNPM_HOME 'global' })
    )) {
        if ($pnpmRoot -and (Test-Path -LiteralPath $pnpmRoot -PathType Container)) {
            foreach ($versionRoot in @(Get-ChildItem -LiteralPath $pnpmRoot -Directory -ErrorAction SilentlyContinue)) {
                foreach ($instanceRoot in @(Get-ChildItem -LiteralPath $versionRoot.FullName -Directory -ErrorAction SilentlyContinue)) {
                    Add-Root (Join-Path $instanceRoot.FullName 'node_modules')
                }
            }
        }
    }

    $wrapper = Find-CodexAcpWrapper $Manager
    if ($wrapper) { Add-Root (Join-Path (Split-Path -Parent $wrapper) 'node_modules') }

    foreach ($root in $roots) {
        foreach ($candidate in @(
            (Join-Path $root "@zed-industries\$platformPackage\bin\codex-acp.exe"),
            (Join-Path $root "@zed-industries\codex-acp\node_modules\@zed-industries\$platformPackage\bin\codex-acp.exe"),
            (Join-Path $root ".pnpm\node_modules\@zed-industries\$platformPackage\bin\codex-acp.exe")
        )) {
            if (Test-Path -LiteralPath $candidate -PathType Leaf) { return [IO.Path]::GetFullPath($candidate) }
        }
        $fallback = Get-ChildItem -LiteralPath $root -Filter 'codex-acp.exe' -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match "[\\/]@zed-industries[\\/]$([regex]::Escape($platformPackage))[\\/]bin[\\/]codex-acp\.exe$" } |
            Select-Object -First 1
        if ($fallback) { return $fallback.FullName }
    }
    $null
}

function Test-CodexAcpRuntime([string]$Manager = '', [switch]$Quiet) {
    $wrapper = Find-CodexAcpWrapper $Manager
    $native = Find-CodexAcpNativeBinary $Manager
    if (-not $wrapper -or -not $native) {
        if (-not $Quiet) { Write-Host "MISSING Codex ACP wrapper/native runtime: expected $script:CodexAcpPackage and $(Get-CodexAcpPlatformPackage)" }
        return $false
    }
    & $native --help *> $null
    if ($LASTEXITCODE -ne 0) {
        if (-not $Quiet) { Write-Host "BROKEN Codex ACP native runtime: $native returned exit $LASTEXITCODE for --help" }
        return $false
    }
    if (-not $Quiet) { Write-Ok "Codex ACP native runtime ready: $native" }
    $true
}

function Install-CodexAcp([object]$Row) {
    $manager = Get-NodePackageManager
    if ((Test-CodexAcpRuntime $manager -Quiet) -and -not $Update) { return }
    if (-not $manager) { throw 'Codex ACP requires an existing Node package manager. Install pnpm or npm through ShipGlows, then rerun -Only codex-acp.' }
    if ($DryRun) { Write-Plan "would install $($Row.node_package) with $([IO.Path]::GetFileName($manager)) and require $(Get-CodexAcpPlatformPackage)"; return }

    $managerName = [IO.Path]::GetFileName($manager).ToLowerInvariant()
    $arguments = if ($managerName.StartsWith('pnpm')) { @('add','--global','--config.optional=true',$Row.node_package) } else { @('install','--global','--include=optional',$Row.node_package) }
    Write-Info "Installing $($Row.node_package) with $managerName."
    & $manager @arguments | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "$managerName failed to install $($Row.node_package) (exit $LASTEXITCODE)." }
    Update-ProcessPath
    if (-not (Test-CodexAcpRuntime $manager)) {
        throw "Node reported success, but the Codex ACP wrapper or native $(Get-CodexAcpPlatformPackage) runtime is missing/broken. Optional dependencies must remain enabled; no package store was removed."
    }
}

function Assert-ModeContract {
    $modeCount = @($Check, $Update, $Uninstall).Where({ $_ }).Count
    if ($modeCount -gt 1) { throw 'Choose only one of -Check, -Update, or -Uninstall.' }
    if ($DryRun -and $modeCount) { throw '-DryRun cannot be combined with -Check, -Update, or -Uninstall.' }
    if ($ConfigureWezTerm -and $SkipWezTerm) { throw 'Choose only one of -ConfigureWezTerm or -SkipWezTerm.' }
    if ($ConfigureTools -and $SkipTools) { throw 'Choose only one of -ConfigureTools or -SkipTools.' }
    if ($Uninstall -and ($ConfigureWezTerm -or $SkipWezTerm -or $ConfigureTools -or $SkipTools -or $InstallYaziPlugins)) {
        throw '-Uninstall cannot be combined with configuration or package switches.'
    }
}

function Update-ProcessPath {
    $parts = [Collections.Generic.List[string]]::new()
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($value in @($env:Path, [Environment]::GetEnvironmentVariable('Path', 'User'), [Environment]::GetEnvironmentVariable('Path', 'Machine'))) {
        foreach ($entry in @($value -split ';' | Where-Object { $_ })) {
            if ($seen.Add($entry.Trim())) { $parts.Add($entry.Trim()) }
        }
    }
    $env:Path = $parts -join ';'
}

function Get-WinGet {
    $winget = Get-App 'winget.exe'
    if (-not $winget) { throw 'WinGet is unavailable. Install Microsoft App Installer, reopen the terminal, and rerun.' }
    $winget.Source
}

function Invoke-Git([string]$Git, [string[]]$Arguments) {
    & $Git @Arguments | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "Git failed: git $($Arguments -join ' ')" }
}

function Invoke-GitText([string]$Git, [string[]]$Arguments) {
    $output = @(& $Git @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Git failed: git $($Arguments -join ' '): $($output -join ' ')" }
    ($output -join "`n").Trim()
}

function Normalize-RepoUrl([string]$Url) { (($Url.Trim() -replace '\\','/') -replace '\.git$','').TrimEnd('/').ToLowerInvariant() }

function Ensure-Git {
    $git = Get-App 'git.exe'
    if ($git) { return $git.Source }
    if ($Check -or $DryRun -or $Uninstall) { throw 'git.exe is missing; read-only mode will not install it.' }
    $winget = Get-WinGet
    & $winget install --id Git.Git --exact --source winget --accept-package-agreements --accept-source-agreements --silent --disable-interactivity | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "WinGet could not install Git (exit $LASTEXITCODE)." }
    Update-ProcessPath
    $git = Get-App 'git.exe'
    if (-not $git) { throw 'Git installed but is not visible yet. Open a new terminal and rerun.' }
    $git.Source
}

function Test-Checkout([string]$Git) {
    if (-not (Test-Path -LiteralPath $DotfilesDir)) { return $false }
    if (-not (Test-Path -LiteralPath (Join-Path $DotfilesDir '.git'))) { throw "$DotfilesDir exists but is not a Git checkout; it was left unchanged." }
    $origin = Invoke-GitText $Git @('-C',$DotfilesDir,'remote','get-url','origin')
    if ((Normalize-RepoUrl $origin) -ne (Normalize-RepoUrl $RepoUrl)) { throw "Origin mismatch. Expected '$RepoUrl', found '$origin'." }
    $dirty = Invoke-GitText $Git @('-C',$DotfilesDir,'status','--porcelain')
    if ($dirty) { throw 'Local changes were found. Commit or stash them; this installer never resets or stashes.' }
    $current = Invoke-GitText $Git @('-C',$DotfilesDir,'branch','--show-current')
    if ($current -ne $Branch) { throw "Checkout branch '$current' does not match '$Branch'; switch it explicitly." }
    $true
}

function Sync-Checkout {
    if ($DryRun -and -not (Test-Path -LiteralPath $DotfilesDir)) { Write-Plan "would clone $RepoUrl ($Branch) to $DotfilesDir"; return }
    $git = Ensure-Git
    if (Test-Checkout $git) {
        if ($Update) {
            Invoke-Git $git @('-C',$DotfilesDir,'fetch','origin',$Branch)
            Invoke-Git $git @('-C',$DotfilesDir,'merge','--ff-only',"origin/$Branch")
        }
        return
    }
    if ($Check) { throw "Installed runtime not found at $DotfilesDir." }
    $parent = Split-Path -Parent $DotfilesDir
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    Invoke-Git $git @('clone','--branch',$Branch,'--single-branch',$RepoUrl,$DotfilesDir)
}

function Get-ManifestPath {
    foreach ($path in @((Join-Path $DotfilesDir 'dotfiles\components.tsv'), (Join-Path $PSScriptRoot 'dotfiles\components.tsv'))) {
        if (Test-Path -LiteralPath $path -PathType Leaf) { return $path }
    }
    throw 'components.tsv is unavailable. Run from the repository or complete the checkout first.'
}

function Read-Manifest {
    $rows = @(Import-Csv -LiteralPath (Get-ManifestPath) -Delimiter "`t")
    $required = @('id','owner','platforms','profile','deps','winget_package','node_package','config_source','target_windows','mode_windows','conflict_policy','privilege','health_probe')
    if (-not $rows) { throw 'components.tsv has no components.' }
    foreach ($name in $required) { if ($rows[0].PSObject.Properties.Name -notcontains $name) { throw "Missing manifest column '$name'." } }
    $ids = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($row in $rows) {
        if ($row.id -notmatch '^[a-z0-9][a-z0-9-]*$' -or -not $ids.Add($row.id)) { throw "Invalid or duplicate component '$($row.id)'." }
        if ($row.owner -ne 'dotfiles' -or $row.conflict_policy -ne 'backup') { throw "Unsafe ownership/conflict policy for '$($row.id)'." }
    }
    @($rows | Where-Object { $_.platforms -split ',' -contains 'windows' })
}

function Select-Components([object[]]$Rows) {
    $requested = [Collections.Generic.List[string]]::new()
    foreach ($value in @($Only)) { foreach ($id in @($value -split ',' | ForEach-Object Trim | Where-Object { $_ })) { $requested.Add($id) } }
    if (-not $requested.Count) { foreach ($row in $Rows | Where-Object profile -eq 'core') { $requested.Add($row.id) } }
    if ($ConfigureWezTerm -and -not $requested.Contains('wezterm')) { $requested.Add('wezterm') }
    if ($SkipWezTerm) { [void]$requested.Remove('wezterm') }
    $map = @{}; foreach ($row in $Rows) { $map[$row.id] = $row }
    foreach ($id in $requested) { if (-not $map.ContainsKey($id)) { throw "Unknown or unsupported Windows component '$id'." } }
    $result = [Collections.Generic.List[object]]::new(); $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    function Add-Component([string]$Id) {
        if (-not $seen.Add($Id)) { return }; $row = $map[$Id]
        foreach ($dep in @($row.deps -split ',' | ForEach-Object Trim | Where-Object { $_ -and $_ -ne '-' })) {
            if (-not $map.ContainsKey($dep)) { throw "Unavailable dependency '$dep' for '$Id'." }; Add-Component $dep
        }
        $result.Add($row)
    }
    foreach ($id in $requested) { Add-Component $id }; @($result)
}

function Resolve-TokenPath([string]$Value) {
    if (-not $Value -or $Value -eq '-') { return $null }
    [IO.Path]::GetFullPath($Value.Replace('${HOME}',$env:USERPROFILE).Replace('${LOCALAPPDATA}',$env:LOCALAPPDATA).Replace('${APPDATA}',$env:APPDATA))
}

function Assert-UserTarget([string]$Target) {
    $full = [IO.Path]::GetFullPath($Target).TrimEnd('\')
    $allowed = @($env:USERPROFILE,$env:LOCALAPPDATA,$env:APPDATA) | Where-Object { $_ } | ForEach-Object { [IO.Path]::GetFullPath($_).TrimEnd('\') }
    if (-not ($allowed | Where-Object { $full -ieq $_ -or $full.StartsWith("$_\",[StringComparison]::OrdinalIgnoreCase) })) { throw "Refusing target outside the user profile: $full" }
}

function Test-ArtifactConverged([object]$Row, [string]$Source, [string]$Target, [string]$Mode) {
    if ($Mode -eq 'path') {
        $entries = @([Environment]::GetEnvironmentVariable('Path','User') -split ';' | Where-Object { $_ })
        return @($entries | Where-Object { [IO.Path]::GetFullPath($_).TrimEnd('\') -ieq $Source.TrimEnd('\') }).Count -gt 0
    }
    if (-not (Test-Path -LiteralPath $Target)) { return $false }
    if ($Mode -eq 'junction') {
        $item = Get-Item -LiteralPath $Target -Force
        $link = @($item.Target)[0]
        return $item.LinkType -in @('Junction','SymbolicLink') -and $link -and [IO.Path]::GetFullPath($link).TrimEnd('\') -ieq $Source.TrimEnd('\')
    }
    if ($Mode -eq 'copy') {
        if (-not (Test-Path -LiteralPath $Source -PathType Leaf) -or -not (Test-Path -LiteralPath $Target -PathType Leaf)) { return $false }
        return (Get-FileHash -LiteralPath $Source).Hash -eq (Get-FileHash -LiteralPath $Target).Hash
    }
    return $false
}

function Ensure-State {
    if (-not (Test-Path -LiteralPath $StateDir)) { New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }
    if (-not (Test-Path -LiteralPath $script:JournalPath)) { "platform`tcomponent`ttarget`tsource`tkind`tbackup`tproof" | Set-Content -LiteralPath $script:JournalPath -Encoding utf8 }
}

function Add-Journal($Component,$Target,$Source,$Kind,$Backup,$Proof) {
    foreach ($value in @($Component,$Target,$Source,$Kind,$Backup,$Proof)) { if ($value -match "[`t`r`n]") { throw 'Unsafe journal value.' } }
    Ensure-State; "windows`t$Component`t$Target`t$Source`t$Kind`t$Backup`t$Proof" | Add-Content -LiteralPath $script:JournalPath -Encoding utf8
}

function Backup-Target([string]$Component,[string]$Target) {
    if (-not (Test-Path -LiteralPath $Target)) { return '' }
    $root = Join-Path $StateDir ('backups\' + (Get-Date -Format 'yyyyMMdd-HHmmssfff')); New-Item -ItemType Directory -Path $root -Force | Out-Null
    $backup = Join-Path $root ($Component + '-' + [Guid]::NewGuid().ToString('N')); Move-Item -LiteralPath $Target -Destination $backup
    Write-Info "Preserved existing target in $backup"; $backup
}

function Install-Artifact([object]$Row) {
    $mode = $row.mode_windows; if (-not $mode -or $mode -eq 'none') { return }
    $source = if ($row.config_source -and $row.config_source -ne '-') { [IO.Path]::GetFullPath((Join-Path $script:SourceRoot $row.config_source)) } else { '' }
    $target = if ($mode -eq 'path') { $source } else { Resolve-TokenPath $row.target_windows }
    Assert-UserTarget $target
    if (Test-ArtifactConverged $row $source $target $mode) { return }
    if ($DryRun) { Write-Plan "would install $($row.id) at $target ($mode)"; return }
    if ($mode -in @('copy','junction') -and -not (Test-Path -LiteralPath $source)) { throw "Missing source for '$($row.id)': $source" }
    if ($mode -eq 'junction') {
        $item = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
        if ($item -and $item.LinkType -in @('Junction','SymbolicLink') -and [IO.Path]::GetFullPath(@($item.Target)[0]).TrimEnd('\') -ieq $source.TrimEnd('\')) { return }
        $backup = Backup-Target $row.id $target; New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        New-Item -ItemType Junction -Path $target -Target $source | Out-Null; Add-Journal $row.id $target $source $mode $backup ('link:'+$source.TrimEnd('\')); return
    }
    if ($mode -eq 'copy') {
        if ((Test-Path $target -PathType Leaf) -and (Get-FileHash $source).Hash -eq (Get-FileHash $target).Hash) { return }
        $backup = Backup-Target $row.id $target; New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        Copy-Item -LiteralPath $source -Destination $target; Add-Journal $row.id $target $source $mode $backup ('sha256:'+(Get-FileHash $target).Hash.ToLowerInvariant()); return
    }
    if ($mode -eq 'path') {
        $entry = [IO.Path]::GetFullPath($source).TrimEnd('\'); $userPath = [Environment]::GetEnvironmentVariable('Path','User'); $entries = @($userPath -split ';' | Where-Object { $_ })
        if ($entries | Where-Object { [IO.Path]::GetFullPath($_).TrimEnd('\') -ieq $entry }) { return }
        [Environment]::SetEnvironmentVariable('Path',(@($entries)+$entry)-join ';','User'); Update-ProcessPath; Add-Journal $row.id $entry $entry path '' ('path:'+$entry); return
    }
    throw "Unsupported Windows mode '$mode'."
}

function Install-Package([object]$Row) {
    if ($SkipTools) { return }
    if ($Row.node_package -and $Row.node_package -ne '-') { Install-CodexAcp $Row; return }
    if (-not $Row.winget_package -or $Row.winget_package -eq '-' -or -not $Row.health_probe -or $Row.health_probe -eq '-') { return }
    $installed = Test-HealthProbe $Row.health_probe
    if ($installed -and -not $Update) { return }
    if ($DryRun) { Write-Plan "would install or update $($Row.id) with WinGet package $($Row.winget_package)"; return }
    $winget = Get-WinGet; $verb = if ($installed -and $Update) { 'upgrade' } else { 'install' }
    & $winget $verb --id $Row.winget_package --exact --source winget --accept-package-agreements --accept-source-agreements --silent --disable-interactivity | Out-Null
    $exitCode = $LASTEXITCODE
    if (-not (Test-WinGetConvergedExitCode $verb $exitCode)) { throw "WinGet $verb failed for '$($Row.id)' (exit $exitCode)." }
    if ($verb -eq 'upgrade' -and $exitCode -eq -1978335189) { Write-Ok "$($Row.id) is already at the latest applicable WinGet version." }
    Update-ProcessPath
    $available = Test-HealthProbe $Row.health_probe
    if (-not $available) { throw "WinGet reported success for '$($Row.id)', but its health probe is unavailable. Open a new terminal and rerun." }
}

function Test-WinGetConvergedExitCode([string]$Verb, [int]$ExitCode) {
    $ExitCode -eq 0 -or ($Verb -eq 'upgrade' -and $ExitCode -eq -1978335189)
}

function Test-HealthProbe([string]$Expression) {
    if (-not $Expression -or $Expression -eq '-') { return $true }
    foreach ($requirement in @($Expression -split '&' | ForEach-Object Trim | Where-Object { $_ })) {
        if (-not @($requirement -split '\|' | ForEach-Object Trim | Where-Object { $_ -and (Get-App $_) }).Count) { return $false }
    }
    $true
}

function Test-Component([object]$Row) {
    $healthy = $true
    if ($Row.node_package -and $Row.node_package -ne '-') {
        if (-not (Test-CodexAcpRuntime (Get-NodePackageManager))) { $healthy=$false }
    } elseif (-not (Test-HealthProbe $Row.health_probe)) {
        Write-Host "MISSING command: $($Row.health_probe) [$($Row.id)]"; $healthy=$false
    }
    if ($Row.mode_windows -and $Row.mode_windows -notin @('none','path')) { $target=Resolve-TokenPath $Row.target_windows; if (-not (Test-Path -LiteralPath $target)) { Write-Host "MISSING config: $target [$($Row.id)]"; $healthy=$false } }
    if ($Row.id -eq 'yazi' -and $Row.mode_windows -eq 'junction') {
        $target = Resolve-TokenPath $Row.target_windows
        $pluginMain = Join-Path $target 'plugins\git.yazi\main.lua'
        if (-not (Test-Path -LiteralPath $pluginMain)) { Write-Host "MISSING yazi plugin: $pluginMain [$($Row.id)]"; $healthy=$false }
    }
    $healthy
}

function Remove-ManagedArtifacts {
    if (-not (Test-Path -LiteralPath $script:JournalPath -PathType Leaf)) { Write-Info 'No Windows journal exists; nothing is owned for removal.'; return }
    $records=@(Import-Csv $script:JournalPath -Delimiter "`t" | Where-Object platform -eq windows); [array]::Reverse($records)
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($r in $records) {
        if(-not $seen.Add($r.target)){continue}
        if($r.kind -eq 'path') { $entries=@([Environment]::GetEnvironmentVariable('Path','User') -split ';'|Where-Object{$_}); $kept=@($entries|Where-Object{[IO.Path]::GetFullPath($_).TrimEnd('\') -ine [IO.Path]::GetFullPath($r.target).TrimEnd('\')}); if($kept.Count-ne$entries.Count){[Environment]::SetEnvironmentVariable('Path',$kept-join';','User');Update-ProcessPath};continue }
        Assert-UserTarget $r.target; $owned = -not (Test-Path -LiteralPath $r.target)
        if(-not $owned -and $r.kind -eq 'copy'){ $owned=('sha256:'+(Get-FileHash $r.target).Hash.ToLowerInvariant()) -eq $r.proof }
        if(-not $owned -and $r.kind -eq 'junction'){ $item=Get-Item $r.target -Force; $link=@($item.Target)[0]; $owned=$item.LinkType -in @('Junction','SymbolicLink') -and $link -and ('link:'+([IO.Path]::GetFullPath($link).TrimEnd('\'))) -ieq $r.proof }
        if(-not $owned){Write-Host "REFUSED changed target: $($r.target)" -ForegroundColor Red;continue}
        if(Test-Path $r.target){Remove-Item -LiteralPath $r.target -Force}
        if($r.backup -and (Test-Path $r.backup)){New-Item -ItemType Directory -Path(Split-Path -Parent $r.target)-Force|Out-Null;Move-Item $r.backup $r.target;Write-Ok "Restored $($r.target)"}
    }
    Write-Info 'Packages were intentionally left installed.'
}

Assert-ModeContract
Update-ProcessPath
if($Uninstall){Remove-ManagedArtifacts;exit 0}
Sync-Checkout
$script:SourceRoot=if(Test-Path(Join-Path $DotfilesDir 'dotfiles\components.tsv')){[IO.Path]::GetFullPath($DotfilesDir)}else{[IO.Path]::GetFullPath($PSScriptRoot)}
$selected=Select-Components (Read-Manifest)
if($Check){$failed=$false;foreach($row in $selected){if(-not(Test-Component $row)){$failed=$true}};if($failed){throw 'Dotfiles check failed.'};Write-Ok 'Windows Dotfiles check passed.';exit 0}
foreach($row in $selected){Install-Package $row};foreach($row in $selected){Install-Artifact $row}
if($InstallYaziPlugins -and $selected.id -notcontains 'yazi'){throw '-InstallYaziPlugins requires yazi.'}
if($selected.id -contains 'yazi'){
    $fileexe=@("C:\Program Files\Git\usr\bin\file.exe",(Join-Path $env:ProgramFiles 'Git\usr\bin\file.exe'))|Where-Object{Test-Path -LiteralPath $_}|Select-Object -First 1
    if($fileexe -and ([Environment]::GetEnvironmentVariable('YAZI_FILE_ONE','User') -ine $fileexe)){if($DryRun){Write-Plan "would set YAZI_FILE_ONE=$fileexe"}else{[Environment]::SetEnvironmentVariable('YAZI_FILE_ONE',$fileexe,'User')}}
    if($DryRun){Write-Plan 'would run ya pkg install'}else{
        $ya=Get-App 'ya.exe';if(-not $ya){throw 'ya.exe is unavailable after installing Yazi.'}
        & $ya.Source pkg install
        if($LASTEXITCODE-ne0){throw 'ya pkg install failed.'}
    }
}
Write-Ok $(if($DryRun){'Dry-run completed without mutation.'}else{'Windows Dotfiles installation completed.'})
