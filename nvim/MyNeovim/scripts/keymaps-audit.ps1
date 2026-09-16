[CmdletBinding()]
param(
  [ValidateSet("Markdown", "Table")]
  [string]$Format = "Markdown"
)

$repoRoot = Split-Path -Parent $PSScriptRoot
$luaRoot = Join-Path $repoRoot "lua"
$entries = [System.Collections.Generic.List[object]]::new()

Get-ChildItem -LiteralPath $luaRoot -Filter "*.lua" -Recurse | ForEach-Object {
  $relativePath = [System.IO.Path]::GetRelativePath($repoRoot, $_.FullName).Replace("\", "/")
  $content = Get-Content -LiteralPath $_.FullName -Raw

  $directPattern = 'vim\.keymap\.set\(\s*(?<mode>"[^"]+"|\{[^}]+\})\s*,\s*"(?<key>(?:\\.|[^"])*)"'
  [regex]::Matches($content, $directPattern, "Singleline") | ForEach-Object {
    $line = 1 + ($content.Substring(0, $_.Index) -split "`n").Count - 1
    $entries.Add([pscustomobject]@{
      Kind = "direct"
      Mode = ($_.Groups["mode"].Value -replace '\s+', '')
      Key = $_.Groups["key"].Value
      Source = "${relativePath}:$line"
    })
  }

  if ($relativePath.StartsWith("lua/plugins/") -and $content -match 'keys\s*=\s*\{') {
    # Les declarations Lazy avec une notation <...> sont assez distinctives pour
    # eviter de confondre les specs de plugins et leurs tables d'options.
    $lazyPattern = '(?m)^\s*\{\s*"(?<key><[^"]+)"\s*,'
    [regex]::Matches($content, $lazyPattern) | ForEach-Object {
      $line = 1 + ($content.Substring(0, $_.Index) -split "`n").Count - 1
      $entries.Add([pscustomobject]@{
        Kind = "lazy"
        Mode = "plugin"
        Key = $_.Groups["key"].Value
        Source = "${relativePath}:$line"
      })
    }
  }
}

$entries = @($entries | Sort-Object Key, Mode, Source)
$conflicts = @(
  $entries |
    Group-Object Mode, Key -CaseSensitive |
    Where-Object Count -gt 1 |
    Sort-Object Name
)

if ($Format -eq "Table") {
  $entries | Format-Table Kind, Mode, Key, Source -AutoSize
  Write-Host ""
  Write-Host "Doublons potentiels: $($conflicts.Count)"
  $conflicts | ForEach-Object { $_.Group | Format-Table Mode, Key, Source -AutoSize }
  exit $(if ($conflicts.Count -gt 0) { 2 } else { 0 })
}

Write-Output "# Inventaire des raccourcis MyNeovim"
Write-Output ""
Write-Output "> Genere par ``scripts/keymaps-audit.ps1``. Les declarations dynamiques et les mappings internes de plugins peuvent ne pas etre visibles."
Write-Output ""
Write-Output "## Raccourcis declares"
Write-Output ""
Write-Output "| Type | Mode | Touche | Source |"
Write-Output "| --- | --- | --- | --- |"
$entries | ForEach-Object {
  Write-Output "| $($_.Kind) | ``$($_.Mode)`` | ``$($_.Key)`` | ``$($_.Source)`` |"
}
Write-Output ""
Write-Output "## Doublons potentiels"
Write-Output ""
if ($conflicts.Count -eq 0) {
  Write-Output "Aucun doublon litteral detecte pour une meme touche et un meme mode."
} else {
  $conflicts | ForEach-Object {
    $first = $_.Group[0]
    Write-Output "- ``$($first.Mode) $($first.Key)`` : $((($_.Group | ForEach-Object Source) -join ', '))"
  }
}

exit $(if ($conflicts.Count -gt 0) { 2 } else { 0 })
