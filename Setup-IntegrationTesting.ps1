cd C:\Users\mkaufmann\Source\Repos\xSharePointProvisioning

psedit .\DSCResources\ALIS_xList.psm1
psedit .\New-xSharePointProvisioning.ps1
psedit .\Test-ListResource.ps1

#$username       = "**@****.onmicrosoft.com" 
#$password       = "*********" 
#$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force 
#$Credentials    = New-Object System.Management.Automation.PSCredential($username, $securePassword) 
$Credentials = Get-Credential
$Url = "https://****.sharepoint.com/"