$LogFile = "$env:temp\Logfile.log"

# LOGGING FUNCTION
# Based on Adam Bertram's logging script, but with a OutHost parameter to Write to Host in different colors based on severity
# Example: Write-Log -Message "Warning about..." -Severity Warning -OutHost
# Example: Write-Log -Message "Info about..." -OutHost
function Write-Log 
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Information','Warning','Error')]
        [string]$Severity = 'Information',

        [Parameter()]
        [switch]$OutHost = $false
    )
    
    if ($OutHost -and $Severity -eq "Information")
    {
        Write-Host "$Message" -ForegroundColor Green
    }
    elseif ($OutHost -and $Severity -eq "Warning") 
    {
        Write-Host "$Message" -ForegroundColor Yellow
    }
    elseif ($OutHost -and $Severity -eq "Error") 
    {
        Write-Host "$Message" -ForegroundColor Red
    }

    [pscustomobject]@{
        Time = (Get-Date -f g)
        Message = $Message
        Severity = $Severity
    } | Export-Csv -Path "$LogFile" -Append -NoTypeInformation
}
