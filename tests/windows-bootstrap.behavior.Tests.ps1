$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$installer = Join-Path $root 'install-dotfiles.ps1'
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-windows-' + [Guid]::NewGuid().ToString('N'))
$checkout = Join-Path $fixture '.dotfiles'; $state = Join-Path $fixture 'state'
$originalUserProfile = $env:USERPROFILE
$originalLocalAppData = $env:LOCALAPPDATA
New-Item -ItemType Directory -Path $fixture -Force | Out-Null
try {
    & $installer -DryRun -Only neovim -DotfilesDir $checkout -StateDir $state
    if (Test-Path $checkout) { throw 'dry-run created checkout' }; if (Test-Path $state) { throw 'dry-run created state' }
    $yaziPlan = @(& $installer -DryRun -Only yazi -DotfilesDir $checkout -StateDir $state 6>&1 | Out-String)
    if ($yaziPlan -notmatch 'would run ya pkg install') { throw 'Yazi selection did not plan plugin installation' }
    if (Test-Path $checkout) { throw 'Yazi dry-run created checkout' }; if (Test-Path $state) { throw 'Yazi dry-run created state' }
    $rioPlan = @(& $installer -DryRun -Only rio -DotfilesDir $checkout -StateDir $state 6>&1 | Out-String)
    if ($rioPlan -notmatch 'would install rio at .*AppData\\Local\\rio\\config\.toml \(copy\)') { throw 'Rio selection did not plan its Windows configuration copy' }
    if (Test-Path $checkout) { throw 'Rio dry-run created checkout' }; if (Test-Path $state) { throw 'Rio dry-run created state' }
    $codexPlan = @(& $installer -DryRun -Only codex-acp -DotfilesDir $checkout -StateDir $state 6>&1 | Out-String)
    if ($codexPlan -match 'would install .*codex-acp') {
        if ($codexPlan -notmatch '@zed-industries/codex-acp@0\.16\.0') { throw 'Codex ACP dry-run does not expose the pinned Node package' }
        if ($codexPlan -notmatch 'codex-acp-win32-(x64|arm64)') { throw 'Codex ACP dry-run does not expose the required native Windows runtime' }
    }
    if (Test-Path $state) { throw 'Codex ACP dry-run created state' }
    $failed=$false;try{& $installer -DryRun -Only invalid-component -DotfilesDir $checkout -StateDir $state}catch{$failed=$true};if(-not $failed){throw 'invalid component accepted'}
    $failed=$false;try{& $installer -DryRun -Check -DotfilesDir $checkout -StateDir $state}catch{$failed=$true};if(-not $failed){throw 'incompatible modes accepted'}
    $env:USERPROFILE = $fixture
    $starshipTarget = Join-Path $fixture '.config\starship.toml'
    New-Item -ItemType Directory -Path (Split-Path -Parent $starshipTarget) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot '..\starship\starship.toml') -Destination $starshipTarget
    $plan = @(& $installer -DryRun -Only starship -DotfilesDir $checkout -StateDir $state 6>&1 | Out-String)
    if ($plan -match 'would install starship') { throw 'dry-run planned an already-converged copy' }

    $tokens=$null;$parseErrors=$null
    $ast=[Management.Automation.Language.Parser]::ParseFile($installer,[ref]$tokens,[ref]$parseErrors)
    if($parseErrors.Count){throw 'installer function fixture could not parse installer'}
    function Import-InstallerFunction([string]$Name) {
        $definition=$ast.Find({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $Name},$true)
        if(-not $definition){throw "installer function missing: $Name"}
        . ([scriptblock]::Create($definition.Extent.Text))
        Set-Item -Path "Function:\script:$Name" -Value (Get-Item -Path "Function:\$Name").ScriptBlock
    }
    Import-InstallerFunction 'Test-WinGetConvergedExitCode'
    if(-not(Test-WinGetConvergedExitCode upgrade -1978335189)){throw 'WinGet no-applicable-upgrade code was not accepted'}
    if(Test-WinGetConvergedExitCode install -1978335189){throw 'WinGet no-applicable-upgrade code was accepted for install'}
    if(Test-WinGetConvergedExitCode upgrade -1){throw 'unrelated WinGet failure was masked'}

    foreach($name in @('Get-App','Get-CodexAcpPlatformPackage','Get-NodeGlobalRoot','Get-NodeGlobalBin','Find-CodexAcpWrapper','Find-CodexAcpNativeBinary')){Import-InstallerFunction $name}
    $env:LOCALAPPDATA=Join-Path $fixture 'local'
    $architecture=[Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
    $platformPackage="codex-acp-win32-$architecture"
    $pnpmBin=Join-Path $env:LOCALAPPDATA 'pnpm\bin'
    $instanceModules=Join-Path $env:LOCALAPPDATA 'pnpm\global\v11\fixture-instance\node_modules'
    $native=Join-Path $instanceModules ".pnpm\node_modules\@zed-industries\$platformPackage\bin\codex-acp.exe"
    New-Item -ItemType Directory -Path $pnpmBin,(Split-Path -Parent $native) -Force|Out-Null
    Set-Content -LiteralPath (Join-Path $pnpmBin 'codex-acp.CMD') -Value '@exit /b 0' -Encoding ascii
    Copy-Item -LiteralPath $env:ComSpec -Destination $native
    $resolved=Find-CodexAcpNativeBinary
    if($resolved -ne $native){throw "pnpm v11 instance runtime was not resolved: $resolved"}
    if((Find-CodexAcpWrapper) -ne (Join-Path $pnpmBin 'codex-acp.CMD')){throw 'pnpm global bin wrapper was not resolved'}
    'Windows behavior contracts: OK'
} finally { $env:USERPROFILE=$originalUserProfile;$env:LOCALAPPDATA=$originalLocalAppData;Remove-Item -LiteralPath $fixture -Recurse -Force -ErrorAction SilentlyContinue }
