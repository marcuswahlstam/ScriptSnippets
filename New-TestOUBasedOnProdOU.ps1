$prodOUs = Get-ADOrganizationalUnit -Filter * -SearchBase "OU=Koncern root,DC=kahrs,DC=com" -SearchScope OneLevel

foreach ($ou in $prodOUs)
{
    $ouName = $ou.Name
    $ouDN = $ou.DistinguishedName
    $ouDNTest = $ouDN -replace 'OU=Koncern root,DC=kahrs,DC=com','OU=Koncern root - Test,DC=kahrs,DC=com'
    "$ouDNTest"
    New-ADOrganizationalUnit -Path 
}
