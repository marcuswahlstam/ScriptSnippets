<#
Run this script as a repeating Scheduled Task for users. GPO is one possible way.
The Scheduled Task will be removed when this script succeeds.

Author: Marcus Wahlstam, Advitum AB <marcus.wahlstam@advitum.se>
#>

# Set name of Scheduled Task to remove when script is done
$ScheduledTaskName = "Disable autostart of Microsoft Teams"

# Set path to json file
$TeamsDesktopConfigJsonPath = "$env:appdata\Microsoft\Teams\desktop-config.json"

# Exit script if json file does not exist
if (-not (Test-Path -Path $TeamsDesktopConfigJsonPath -PathType Leaf))
{
    exit
}

# Open desktop-config.json file
$desktopConfigFile = Get-Content -path $TeamsDesktopConfigJsonPath -Raw | ConvertFrom-Json

# Set openAtLogin to false
if ($($desktopConfigFile.appPreferenceSettings.openAtLogin) -eq $false)
{
    # openAtLogin is already the correct value
    $RemoveScheduledTask = $true
}
else
{
    try
    {
	    $desktopConfigFile.appPreferenceSettings.openAtLogin = $false
        $desktopConfigFile.PSObject.Properties.Remove("userAccounts")
        
        # Kill Teams if running
        if ((Get-Process Teams -ErrorAction Ignore).Count -gt 0)
        {
            Stop-Process -Name Teams
        }

        # If Teams autorun entry exists, remove it
        $TeamsAutoRun = (Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -ea SilentlyContinue)."com.squirrel.Teams.Teams"
        if ($TeamsAutoRun)
        {
	        Remove-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -Name "com.squirrel.Teams.Teams"
        }

        # Write the change to file
        $desktopConfigFile | ConvertTo-Json -Compress | Set-Content -Path $TeamsDesktopConfigJsonPath -Force
        $RemoveScheduledTask = $true

    } 
    catch 
    {
	    Write-Host  "openAtLogin JSON element doesn't exist"
    }
}

# Remove scheduled task if 
if ($RemoveScheduledTask)
{
    Get-ScheduledTask -TaskName $ScheduledTaskName -ErrorAction Ignore | Unregister-ScheduledTask -Confirm:$false
}
