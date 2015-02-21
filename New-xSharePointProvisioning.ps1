﻿$modulePath = 'C:\Program Files\WindowsPowerShell\Modules'

# Delete module...
Remove-Item -Path "$modulePath\xSharePointProvisioning" -Force -Recurse 

# Create List Resource
$Url         = New-xDscResourceProperty -Name Url             -Type String       -Attribute Key   -Description "The full url to the list."
$Title       = New-xDscResourceProperty -Name Title           -Type String       -Attribute Write -Description "The desired title of the list."
$Ensure      = New-xDscResourceProperty -Name Ensure          -Type String       -Attribute Write -Description "Set this to 'Present' to ensure that the list is present. Set it to 'Absent' to ensure that the list is deleted. Default: 'Present'." -ValidateSet @("Present", "Absent")
$Description = New-xDscResourceProperty -Name Description     -Type String       -Attribute Write -Description "The desired description of the list."
$TemplateId  = New-xDscResourceProperty -Name Template        -Type String       -Attribute Write -Description "The template for of the list (default: genericList)."
$credential  = New-xDscResourceProperty -Name Credentials     -Type PSCredential -Attribute Write -Description "The credentials to use to login to the site."

New-xDscResource -Name ALIS_xList -FriendlyName xList -ModuleName xSharePointProvisioning -Property @($Url, $Ensure, $Title, $Description, $TemplateId, $credential) -Path $modulePath

Copy-Item .\DSCResources\ALIS_xList.psm1 "$modulePath\xSharePointProvisioning\DSCResources\ALIS_xList\ALIS_xList.psm1" -force

Get-DscResource -Name xList 

Test-xDscResource -Name xList -Verbose

copy-item .\xSharePointProvisioning.psd1 "$modulePath\xSharePointProvisioning\xSharePointProvisioning.psd1"