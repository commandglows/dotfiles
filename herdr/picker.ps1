param(
    [string]$Select = "",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$herdr = "herdr"

function Invoke-Herdr {
    param([string[]]$HerdrArgs)
    $out = & $herdr @HerdrArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "herdr $($HerdrArgs -join ' ') failed: $out"
    }
    return (($out -join "`n") | ConvertFrom-Json)
}

function New-TabPanes {
    param(
        [string]$PaneId,
        [object[]]$Panes
    )

    $panes = @($Panes)
    if ($panes.Count -eq 0) {
        $bottom = Invoke-Herdr @("pane", "split", $PaneId, "--direction", "down", "--ratio", "0.8", "--no-focus")
        $nvim = Invoke-Herdr @("pane", "split", $PaneId, "--direction", "right", "--ratio", "0.5", "--no-focus")
        [void](Invoke-Herdr @("pane", "run", $PaneId, "crush"))
        Start-Sleep -Milliseconds 300
        [void](Invoke-Herdr @("pane", "run", $nvim.result.pane.pane_id, "nvim"))
        return
    }

    $prevPane = $PaneId
    $cmdPane = $PaneId
    $cmd = $null

    for ($i = 1; $i -lt $panes.Count; $i++) {
        $p = $panes[$i]
        $direction = "down"
        if ($p.PSObject.Properties["split"] -and $p.split) { $direction = $p.split }
        $splitArgs = @("pane", "split", $prevPane, "--direction", $direction, "--no-focus")
        if ($p.PSObject.Properties["ratio"] -and $p.ratio) { $splitArgs += @("--ratio", "$($p.ratio)") }
        $split = Invoke-Herdr $splitArgs
        $prevPane = $split.result.pane.pane_id
    }

    for ($i = $panes.Count - 1; $i -ge 0; $i--) {
        if ($panes[$i].PSObject.Properties["command"] -and $panes[$i].command) {
            $cmd = $panes[$i].command
            if ($i -eq 0) { $cmdPane = $PaneId } else { $cmdPane = $prevPane }
            break
        }
    }

    if ($cmd) {
        Start-Sleep -Milliseconds 300
        [void](Invoke-Herdr @("pane", "run", $cmdPane, $cmd))
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$config = Get-Content (Join-Path $scriptDir "projects.json") -Raw | ConvertFrom-Json
$projects = @($config.projects) | Where-Object { $_ }

if ($config.PSObject.Properties["auto_scan"] -and $config.auto_scan) {
    $expand = @()
    if ($config.auto_scan.PSObject.Properties["expand"]) { $expand = @($config.auto_scan.expand) }
    $scanned = Get-ChildItem -Path $config.auto_scan.root -Directory | ForEach-Object {
        if ($_.Name -in $expand) {
            Get-ChildItem -Path $_.FullName -Directory | ForEach-Object {
                [pscustomobject]@{ name = $_.Name; cwd = $_.FullName; tabs = $null }
            }
        }
        else {
            [pscustomobject]@{ name = $_.Name; cwd = $_.FullName; tabs = $null }
        }
    }
    $projects = @($projects + $scanned) | Sort-Object name -Unique
}

$project = $null
if ($Select) {
    $project = $projects | Where-Object { $_.name -eq $Select } | Select-Object -First 1
    if (-not $project) { throw "No project named '$Select' in projects.json" }
}
else {
    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        $entries = $projects | ForEach-Object { "$($_.name)`t$($_.cwd)" }
        $picked = $entries | fzf --height 100% --prompt "project> " --with-nth 1 --delimiter "`t"
        if (-not $picked) { exit 0 }
        $name = ($picked -split "`t")[0]
        $project = $projects | Where-Object { $_.name -eq $name } | Select-Object -First 1
    }
    else {
        for ($i = 0; $i -lt $projects.Count; $i++) {
            Write-Host "  [$($i + 1)] $($projects[$i].name)  $($projects[$i].cwd)"
        }
        $idx = [int](Read-Host "project number") - 1
        if ($idx -lt 0 -or $idx -ge $projects.Count) { exit 0 }
        $project = $projects[$idx]
    }
}

if ($DryRun) {
    Write-Host "Would create workspace '$($project.name)' at $($project.cwd) with $(@($project.tabs).Count) tab(s)"
    exit 0
}

$ws = Invoke-Herdr @("workspace", "create", "--cwd", $project.cwd, "--label", $project.name, "--no-focus")
$workspaceId = $ws.result.workspace.workspace_id

$tabs = @($project.tabs) | Where-Object { $_ }
if ($tabs.Count -eq 0) { $tabs = @([pscustomobject]@{ label = "main" }) }

for ($t = 0; $t -lt $tabs.Count; $t++) {
    $tab = $tabs[$t]
    $panes = $null
    if ($tab.PSObject.Properties["panes"]) { $panes = @($tab.panes) }

    if ($t -eq 0) {
        $paneId = $ws.result.root_pane.pane_id
        $label = "main"
        if ($tab.PSObject.Properties["label"] -and $tab.label) { $label = $tab.label }
        if ($label -ne "main") {
            [void](Invoke-Herdr @("tab", "rename", $ws.result.tab.tab_id, $label))
        }
    }
    else {
        $label = "$($t + 1)"
        if ($tab.PSObject.Properties["label"] -and $tab.label) { $label = $tab.label }
        $created = Invoke-Herdr @("tab", "create", "--workspace", $workspaceId, "--label", $label, "--no-focus")
        $paneId = $created.result.root_pane.pane_id
    }

    New-TabPanes -PaneId $paneId -Panes $panes
}

[void](Invoke-Herdr @("workspace", "focus", $workspaceId))
Write-Host "Opened $($project.name) ($workspaceId)"
