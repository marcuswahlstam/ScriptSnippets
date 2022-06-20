#Version:3

# Get user profiles on computer
$LocalUserProfiles = Get-ChildItem $(Join-Path $env:SystemDrive "Users")

# Look through all the profiles if json-config exists
foreach ($Profile in $LocalUserProfiles)
{
    $JsonPath = Join-Path $($Profile.Fullname) "Appdata\Roaming\Microsoft\Teams\desktop-config.json"
    if (Test-Path $JsonPath -PathType Leaf)
    {
        $JsonPath = Get-Item $JsonPath
        $ProfileName = $Profile.Name
        $UserSID = (New-Object System.Security.Principal.NTAccount($ProfileName)).Translate([System.Security.Principal.SecurityIdentifier]).value
        $DoNotRunFile = Join-Path $($JsonPath.PSParentPath) "SKBDisabledAutostart.txt"

        # If DoNotRun file exists, skip this profile
        if (Test-Path $DoNotRunFile -PathType Leaf)
        {
            continue
        }

        # Open desktop-config.json file
        $desktopConfigFile = Get-Content -Path $JsonPath.FullName -Raw | ConvertFrom-Json

        # Set openAtLogin to false
        if ($($desktopConfigFile.appPreferenceSettings.openAtLogin) -eq $false)
        {
            # openAtLogin is already the correct value
            # Create a text file in same directory as json file to identify that this script should not run 
            "AutostartDisabled" | Out-File $DoNotRunFile -Force
        }
        else
        {
            try
            {
                # Change openAtLogin to false
	            $desktopConfigFile.appPreferenceSettings.openAtLogin = $false

                # Delete userAccounts blob in json, json file will be corrupt if not
                $desktopConfigFile.PSObject.Properties.Remove("userAccounts")

                # Write the change to file
                $desktopConfigFile | ConvertTo-Json -Compress | Set-Content -Path $JsonPath.FullName -Force
        
                # If Teams autorun entry exists, remove it
                New-PSDrive HKU Registry HKEY_USERS | Out-Null
                $TeamsAutoRun = (Get-ItemProperty HKU:\$UserSID\Software\Microsoft\Windows\CurrentVersion\Run -ea SilentlyContinue)."com.squirrel.Teams.Teams"
                if ($TeamsAutoRun)
                {
	                Remove-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -Name "com.squirrel.Teams.Teams"
                }
                Remove-PSDrive HKU

                # Create a text file in same directory as json file to identify that this script should not run 
                "AutostartDisabled" | Out-File $DoNotRunFile -Force

            } 
            catch 
            {
	            Write-Host  "openAtLogin JSON element doesn't exist"
            }
        }
    }
}
