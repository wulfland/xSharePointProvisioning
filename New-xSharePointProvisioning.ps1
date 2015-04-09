$modulePath = 'C:\Program Files\WindowsPowerShell\Modules'

cd $PSScriptRoot

# Delete module...
Remove-Item -Path "$modulePath\xSharePointProvisioning" -Force -Recurse 

# Create List Resource
$Url         = New-xDscResourceProperty -Name Url             -Type String       -Attribute Key       -Description "The full url to the list."
$Title       = New-xDscResourceProperty -Name Title           -Type String       -Attribute Write     -Description "The desired title of the list."
$Ensure      = New-xDscResourceProperty -Name Ensure          -Type String       -Attribute Write     -Description "Set this to 'Present' to ensure that the list is present. Set it to 'Absent' to ensure that the list is deleted. Default: 'Present'." -ValidateSet @("Present", "Absent")
$Description = New-xDscResourceProperty -Name Description     -Type String       -Attribute Write     -Description "The desired description of the list."
$TemplateId  = New-xDscResourceProperty -Name Template        -Type String       -Attribute Write     -Description "The template for of the list (default: genericList)."
$credential  = New-xDscResourceProperty -Name Credentials     -Type PSCredential -Attribute Write     -Description "The credentials to use to login to the site."

New-xDscResource -Name ALIS_xList -FriendlyName xList -ModuleName xSharePointProvisioning -Property @($Url, $Ensure, $Title, $Description, $TemplateId, $credential) -Path $modulePath

Copy-Item .\DSCResources\ALIS_xList.psm1 "$modulePath\xSharePointProvisioning\DSCResources\ALIS_xList\ALIS_xList.psm1" -force

#Get-DscResource -Name xList 
#Test-xDscResource -Name xList -Verbose

# Create Field Resource
$FieldXml    = New-xDscResourceProperty -Name FieldXml        -Type String       -Attribute Key        -Description "The xml that represents the field."
$Url         = New-xDscResourceProperty -Name Url             -Type String       -Attribute Required   -Description "The full url to the list."
$Ensure      = New-xDscResourceProperty -Name Ensure          -Type String       -Attribute Write      -Description "Set this to 'Present' to ensure that the field is present. Set it to 'Absent' to ensure that the field is deleted. Default: 'Present'." -ValidateSet @("Present", "Absent")
$credential  = New-xDscResourceProperty -Name Credentials     -Type PSCredential -Attribute Write      -Description "The credentials to use to login to the site."

New-xDscResource -Name ALIS_xField -FriendlyName xField -ModuleName xSharePointProvisioning -Property @($FieldXml, $Url, $Ensure, $credential) -Path $modulePath

Copy-Item .\DSCResources\ALIS_xField.psm1 "$modulePath\xSharePointProvisioning\DSCResources\ALIS_xField\ALIS_xField.psm1" -force

#Get-DscResource -Name xField
#Test-xDscResource -Name xField -Verbose

# Create ListItem Resource
$Title       = New-xDscResourceProperty -Name Title           -Type String       -Attribute Key        -Description "The tiel of the listitem." 
$Url         = New-xDscResourceProperty -Name Url             -Type String       -Attribute Required   -Description "The full url to the list."
$Ensure      = New-xDscResourceProperty -Name Ensure          -Type String       -Attribute Write      -Description "Set this to 'Present' to ensure that the item is present. Set it to 'Absent' to ensure that the item is deleted. Default: 'Present'." -ValidateSet @("Present", "Absent")
$Properties  = New-xDscResourceProperty -Name Properties      -Type Hashtable[]  -Attribute Write      -Description "The properties of the listitem."
$credential  = New-xDscResourceProperty -Name Credentials     -Type PSCredential -Attribute Write      -Description "The credentials to use to login to the site."

New-xDscResource -Name ALIS_xListItem -FriendlyName xListItem -ModuleName xSharePointProvisioning -Property @($Title, $Url, $Ensure, $Properties, $credential) -Path $modulePath

Copy-Item .\DSCResources\ALIS_xListItem.psm1 "$modulePath\xSharePointProvisioning\DSCResources\ALIS_xListItem\ALIS_xListItem.psm1" -force

#Get-DscResource -Name xListItem
#Test-xDscResource -Name xListItem -Verbose

$Url         = New-xDscResourceProperty -Name Url             -Type String       -Attribute Key      -Description "The full url of the file."
$SourcePath  = New-xDscResourceProperty -Name SourcePath      -Type String       -Attribute Required -Description "The local path of the file."
$Ensure      = New-xDscResourceProperty -Name Ensure          -Type String       -Attribute Write    -Description "Set this to 'Present' to ensure that the file is present. Set it to 'Absent' to ensure that the file is deleted. Default: 'Present'." -ValidateSet @("Present", "Absent")
$Properties  = New-xDscResourceProperty -Name Properties      -Type Hashtable[]  -Attribute Write    -Description "The properties of the file."
$credential  = New-xDscResourceProperty -Name Credentials     -Type PSCredential -Attribute Write    -Description "The credentials to use to login to the site."

New-xDscResource -Name ALIS_xFile -FriendlyName xFile -ModuleName xSharePointProvisioning -Property @($Url, $SourcePath, $Ensure, $Properties, $credential) -Path $modulePath

Copy-Item .\DSCResources\ALIS_xFile.psm1 "$modulePath\xSharePointProvisioning\DSCResources\ALIS_xFile\ALIS_xFile.psm1" -force

Get-DscResource -Name xFile
Test-xDscResource -Name xFile -Verbose

# Override module
copy-item .\xSharePointProvisioning.psd1 "$modulePath\xSharePointProvisioning\xSharePointProvisioning.psd1" -Force