$driver = Get-WmiObject Win32_PnPSignedDriver | where {$_.devicename -like "*ethernet*" -and $_.driverprovidername -like "*intel*"}
$driverVersion = $driver.driverversion
$newDriverVersion = "12.18.9.10"

if ([version]('{0}.{1}.{2}.{3}' -f $driverVersion.split('.')) -lt [version]('{0}.{1}.{2}.{3}' -f $newDriverVersion.split('.')))
{
    Start-Process "$PSScriptRoot\igxpin.exe" -ArgumentList '-s' -Wait
}
