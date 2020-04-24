Function Get-TaskSequenceStatus
{
	try
	{
		$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
	}
	catch{}

	if($NULL -eq $TSEnv)
	{
		return $False
	}
	else
	{
		try
		{
			$SMSTSType = $TSEnv.Value("_SMSTSType")
		}
		catch{}

		if($NULL -eq $SMSTSType)
		{
			return $False
		}
		else
		{
			return $True
		}
	}
}

if(Get-TaskSequenceStatus)
{
	$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
	$LogsDirectory = $TSEnv.Value("_SMSTSLogPath")
}
else
{
	$LogsDirectory = "$ENV:ProgramData\BiosScripts\Lenovo"
	if(!(Test-Path -PathType Container $LogsDirectory))
	{
		New-Item -Path $LogsDirectory -ItemType "Directory" -Force | Out-Null
	}
}


# Create Write-Log function
function Write-Log {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message
    )

    Begin
    {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $VerbosePreference = 'Continue'
    }
    Process
    {
        $LogPath = "$LogsDirectory" + "\Config-LenovoBIOS.log"

        if (!(Test-Path $LogPath)) 
        {
            Write-Verbose "Creating $LogPath."
            $NewLogFile = New-Item $LogPath -Force -ItemType File
        }

        # Format Date for our Log File
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # Write log entry to $LogPath
        "$FormattedDate $Message" | Out-File -FilePath $LogPath -Append
    }
    End
    {
    }
}

$UEFI = Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\WMI | Where-Object {$_.CurrentSetting -match "SecureBoot"} | Select-Object CurrentSetting

if ($UEFI -eq $null)
{
    $UEFI = Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\WMI | Where-Object {$_.CurrentSetting -match "Secure Boot"} | Select-Object CurrentSetting
    $UEFIName = $UEFI.CurrentSetting -split(',')
    $Name = $UEFIName[0]
    $Status = ($UEFIName -split ';')[1]
    $Enabled = "Enabled"
}
else
{
    $UEFIName = $UEFI.CurrentSetting -split(',')
    $Name = $UEFIName[0]
    $Status = $UEFIName[1]
    $Enabled = "Enable"
}

Write-Log -Message "Collected Lenovo_BiosSetting information for $Name"
    
if ($Status -like "Disable*")
{

    Write-Log -Message "$Name disabled - trying to activate" 

    try
    {
        $Invocation = (Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi).SetBiosSetting("$Name,$Enabled").return
        $Invocation = (Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi).SaveBiosSettings().return
    }
    catch 
    {
        Write-Log -Message "An error occured while enabling $Name in the BIOS"
    }
}
elseif ($Status -like "Enable*")
{
    Write-Log -Message "$Name already active - doing nothing"
}

if ($Invocation -eq "Success")
{
    Write-Log -Message "$Name was successfully enabled"
}