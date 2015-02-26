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


Configuration TestListItemResource
{
    param
    (
        [Parameter(Mandatory=$false)]
        [PSCredential]$Credential,

        [Parameter(Mandatory=$false)]
        [string]$Url
    )

    Import-DscResource -ModuleName xSharePointProvisioning   -Name ALIS_xListItem
    
    Node $AllNodes.NodeName 
    {
        xListItem TestItem
        {
            Url = "$Url/Lists/MyCustomList"
            Ensure = "Present"
            Title = "My Custom List"
            Properties = @{ 
                MyNumberField = '6' 
                Date = '26/2/2015'
                }
            Credentials = $Credential
        }
    }
}

TestListItemResource -ConfigurationData $ConfigurationData -Url $Url -Credential $Credentials -verbose

Restart-Service Winmgmt -force

Start-DscConfiguration -Path .\TestListItemResource -Wait -Force -Verbose -debug

#Get-DscConfiguration