#cd 'C:\Program Files\WindowsPowerShell\Modules\xSharePointProvisioning\DSCResources\ALIS_xList'

psedit .\ALIS_xList.psm1

Import-Module .\ALIS_xList.psm1

#$username       = "**@****.onmicrosoft.com" 
#$password       = "******" 
#$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force 
#$Credentials    = New-Object System.Management.Automation.PSCredential($username, $securePassword) 

$Credentials = Get-Credential
$Url = "https://****.sharepoint.com"