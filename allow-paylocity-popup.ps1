<#
.SYNOPSIS
    Allows pop-ups and redirects for Paylocity in Google Chrome (and Microsoft Edge)
    via browser policy, so Time & Labor / Timesheets opens without logging users out.

.NOTES
    - Must be run as Administrator. Browser policy keys are protected by Windows,
      so they can't be written from a normal PowerShell window.
    - Applies machine-wide (HKLM), so it covers every user on the PC.
    - Adds to any existing PopupsAllowedForUrls entries instead of overwriting them.
#>

param(
    [switch]$IncludeEdge = $true,
    [string[]]$Urls = @('[*.]paylocity.com')
)

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host ""
    Write-Host "This script needs to run as Administrator." -ForegroundColor Red
    Write-Host "  1. Close this window." -ForegroundColor Red
    Write-Host "  2. Click Start, type PowerShell, right-click it, and choose 'Run as administrator'." -ForegroundColor Red
    Write-Host "  3. Run this script again." -ForegroundColor Red
    exit 1
}

$changed = $false
$failed  = $false

$policyPaths = @("HKLM:\SOFTWARE\Policies\Google\Chrome\PopupsAllowedForUrls")
if ($IncludeEdge) {
    $policyPaths += "HKLM:\SOFTWARE\Policies\Microsoft\Edge\PopupsAllowedForUrls"
}

foreach ($path in $policyPaths) {
    try {
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force -ErrorAction Stop | Out-Null
        }

        # Read existing numbered entries so we don't overwrite them
        $props = Get-ItemProperty -Path $path -ErrorAction Stop
        $existing = @{}
        foreach ($p in $props.PSObject.Properties) {
            if ($p.Name -match '^\d+$') { $existing[[int]$p.Name] = $p.Value }
        }

        foreach ($url in $Urls) {
            if ($existing.Values -contains $url) {
                Write-Host "Already allowed in $path : $url"
                continue
            }
            $next = if ($existing.Count) { ($existing.Keys | Measure-Object -Maximum).Maximum + 1 } else { 1 }
            New-ItemProperty -Path $path -Name "$next" -Value $url -PropertyType String -Force -ErrorAction Stop | Out-Null
            $existing[$next] = $url
            $changed = $true
            Write-Host "Added to $path : $url"
        }
    }
    catch {
        $failed = $true
        Write-Host "Could not update $path : $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($failed) {
    Write-Host "`nSome changes failed. See the messages above." -ForegroundColor Red
    exit 1
}
elseif ($changed) {
    Write-Host "`nDone. Restart the browser or open chrome://policy (edge://policy for Edge) and click 'Reload policies'." -ForegroundColor Red
}
else {
    Write-Host "`nNo changes needed. Paylocity pop-ups are already allowed." -ForegroundColor Green
}
