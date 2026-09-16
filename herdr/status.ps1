# Cross‑platform CPU / RAM status for the herdr overlay
function Get-WindowsStatus {
    $cpu = (wmic cpu get loadpercentage /value).Split('=')[-1].Trim()
    $mem = wmic OS get FreePhysicalMemory,TotalVisibleMemorySize /value
    $free = ($mem -match 'FreePhysicalMemory=(\d+)')[0].Split('=')[-1]
    $total = ($mem -match 'TotalVisibleMemorySize=(\d+)')[0].Split('=')[-1]
    $used = [math]::Round(($total - $free) / 1024, 1)
    $totalGB = [math]::Round($total / 1048576, 1)
    return "CPU $cpu% | RAM $used/$totalGB GB"
function Get-UnixStatus {
    $cpu = (top -bn1 | grep "Cpu(s)" | awk '{print $2+$4}' | sed 's/%//')
    $memInfo = Get-Content /proc/meminfo
    $totalKB = ($memInfo -match '^MemTotal:\s+(\d+)').Groups[1].Value
    $freeKB  = ($memInfo -match '^MemAvailable:\s+(\d+)').Groups[1].Value
    $usedGB  = [math]::Round(($totalKB - $freeKB) / 1024 / 1024, 1)
    $totalGB = [math]::Round($totalKB / 1024 / 1024, 1)
    return "CPU $cpu% | RAM $usedGB/$totalGB GB"
}
# Choose implementation based on platform
if ($IsWindows) {
    $status = Get-WindowsStatus
} else {
    $status = Get-UnixStatus
}
Write-Output $status
"CPU $cpu% | RAM $usedGB/$totalGB GB"
