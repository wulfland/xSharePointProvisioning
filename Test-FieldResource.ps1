if (-not $Url)
{
    $Url = Read-Host "Enter the url to the test site:"
}

if (-not $Credentials)
{
    $Credentials = Get-Credential
}

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName="*"
            PSDscAllowPlainTextPassword=$true
         }
        @{
            NodeName="localhost"
         }
    )
}


Configuration TestFieldResource
{
    param
    (
        [Parameter(Mandatory=$false)]
        [PSCredential]$Credential,

        [Parameter(Mandatory=$false)]
        [string]$Url
    )

    Import-DscResource -ModuleName xSharePointProvisioning   -Name ALIS_xField
    
    Node $AllNodes.NodeName 
    {
        xField TextField
        {
            FieldXml = "<Field Type='Text' DisplayName='My Text Field' Name='MyTextField' />"
            Url = "$Url/Lists/MyCustomList"
            Ensure = "Present"
            Credentials = $Credential
        }

        xField NoteField
        {
            FieldXml = "<Field Type='Note' DisplayName='My Note Field' Name='MyNoteField' />"
            Url = "$Url/Lists/MyCustomList"
            Ensure = "Present"
            Credentials = $Credential
        }

        xField NumberField
        {
            FieldXml = "<Field Type='Number' DisplayName='My Number Field' Name='MyNumberField' />"
            Url = "$Url/Lists/MyCustomList"
            Ensure = "Present"
            Credentials = $Credential
        }
    }
}

TestFieldResource -ConfigurationData $ConfigurationData -Url $Url -Credential $Credentials -verbose

Restart-Service Winmgmt -force

Start-DscConfiguration -Path .\TestFieldResource -Wait -Force -Verbose

Get-DscConfiguration