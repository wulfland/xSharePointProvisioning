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


Configuration TestListResource
{
    param
    (
        [Parameter(Mandatory=$false)]
        [PSCredential]$Credential,

        [Parameter(Mandatory=$false)]
        [string]$Url
    )

    Import-DscResource -ModuleName xSharePointProvisioning   -Name ALIS_xList
    
    Node $AllNodes.NodeName 
    {
        xList GenericList
        {
            Url = "$Url/Lists/MyCustomList"
            Ensure = "Present"
            Title = "My Custom List"
            Description = "A sample generic list..."
            Template = "genericList"
            Credentials = $Credential
        }

        xList DocLib
        {
            Url = "$Url/MyDocuments"
            Ensure = "Present"
            Title = "My Documents"
            Description = "My Document Library"
            Template = "DocumentLibrary"
            Credentials = $Credential
        }
    }
}

TestListResource -ConfigurationData $ConfigurationData -Url $Url -Credential $Credentials -verbose

Restart-Service Winmgmt -force

Start-DscConfiguration -Path .\TestListResource -Wait -Force -Verbose

Get-DscConfiguration