$baseOUProd = "OU=Prod,DC=domain,DC=com"

$OUsInBaseOUProd = Get-ADOrganizationalUnit -Filter * -SearchBase $baseOUProd -SearchScope Subtree | where {$_.DistinguishedName -notlike "*VDI*" -and $_.DistinguishedName -notlike "*GPOtest*"}

$allProdGPO = @()

foreach ($prodOU in $OUsInBaseOUProd)
{
    
    $linkedGPOsProd = $prodOU | Select-object -ExpandProperty LinkedGroupPolicyObjects
    $testOU = $prodOU.DistinguishedName -replace 'OU=Prod,DC=domain,DC=com','OU=Test,DC=domain,DC=com'
    $prodOUName = $prodOU.Name
    "Working on OU $prodOUName"

    foreach ($prodGPO in $linkedGPOsProd)
    {
        # Hämta namn och GUID på aktuell GPO
        $gpoInfoProd = Get-GPO -Guid $($prodGPO.Substring(4,36))
        $gpoNameProd = $gpoInfoProd.DisplayName
        $gpoGUIDProd = $gpoInfoProd.Id
        "Working on GPO $gpoNameProd"

        [xml]$GPOReport = (Get-GPOReport -Name "$gpoNameProd" -ReportType xml)
        $gpoEnabled = ($GPOReport.GPO.LinksTo | where {$_.SOMPath -like "*$prodOUName"}).Enabled
        if ($gpoEnabled -eq "true")
        {
            "Setting link as enabled for GPO $gpoNameProd"
            New-GPLink -Guid $gpoGUIDProd -Target $testOU -LinkEnabled Yes
        }
        else
        {
            "Setting link as disabled for GPO $gpoNameProd"
            New-GPLink -Guid $gpoGUIDProd -Target $testOU -LinkEnabled No
        }
    }
}
