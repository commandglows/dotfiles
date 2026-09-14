$ErrorActionPreference = "Continue"

$paneId = $env:HERDR_PANE_ID
$bin = $env:HERDR_BIN_PATH
$source = "custom:crush"

function Report-State {
    param([string]$State, [string]$Message = "")
    if (-not $paneId -or -not $bin) { return }
    $args = @("pane", "report-agent", $paneId, "--source", $source, "--agent", "crush", "--state", $State)
    if ($Message) { $args += @("--message", $Message) }
    [void](& $bin @args 2>$null)
}

if ($paneId -and $bin) { Report-State -State "working" }

& crush --yolo @args
$crushExit = $LASTEXITCODE

if ($paneId -and $bin) {
    Report-State -State "idle"
    [void](& $bin pane release-agent $paneId --source $source 2>$null)
}
exit $crushExit
