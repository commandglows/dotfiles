$cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$os = Get-CimInstance Win32_OperatingSystem
$usedGB = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 1)
$totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
"CPU $cpu% | RAM $usedGB/$totalGB GB"
