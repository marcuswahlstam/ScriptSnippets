$prodOUs = Get-ADOrganizationalUnit -Filter * -SearchBase "OU=Prod,DC=domain,DC=com" -SearchScope OneLevel

foreach ($ou in $prodOUs)
{
    $ouName = $ou.Name
    $ouDN = $ou.DistinguishedName
    $ouDNTest = $ouDN -replace 'OU=Prod,DC=domain,DC=com','OU=Test,DC=domain,DC=com'
    "$ouDNTest"
    New-ADOrganizationalUnit -Path 
}
