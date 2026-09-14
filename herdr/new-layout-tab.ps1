param(
    [string]$Label = "",
    [switch]$NoCrush
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

$snapshot = Invoke-Herdr @("api", "snapshot")
$workspaceId = $snapshot.result.snapshot.focused_workspace_id
if (-not $workspaceId) { throw "No focused workspace" }

$tabCount = ($snapshot.result.snapshot.layouts | Where-Object { $_.workspace_id -eq $workspaceId }).Count
if (-not $Label) { $Label = "layout $($tabCount + 1)" }

$created = Invoke-Herdr @("tab", "create", "--workspace", $workspaceId, "--label", $Label, "--no-focus")
$tabId = $created.result.tab.tab_id
$rootPane = $created.result.root_pane.pane_id

$bottom = Invoke-Herdr @("pane", "split", $rootPane, "--direction", "down", "--ratio", "0.8", "--no-focus")
$nvim = Invoke-Herdr @("pane", "split", $rootPane, "--direction", "right", "--ratio", "0.5", "--no-focus")

if (-not $NoCrush) {
    Start-Sleep -Milliseconds 300
    [void](Invoke-Herdr @("pane", "run", $rootPane, "C:\\Users\\Diane\\ShipGlows\\dotfiles\\herdr\\crush-herdr.ps1"))
}
Start-Sleep -Milliseconds 300
[void](Invoke-Herdr @("pane", "run", $nvim.result.pane.pane_id, "nvim"))

[void](Invoke-Herdr @("tab", "focus", $tabId))
Write-Host "Created tab '$Label' in $workspaceId"
