$username       = "mk@mkaufmann.onmicrosoft.com" 
$password       = "xxxxxxxxx" 
$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force 
$Credentials    = New-Object System.Management.Automation.PSCredential($username, $securePassword) 

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
        [PSCredential]$Credential
    )

    Import-DscResource -ModuleName xSharePointProvisioning   -Name ALIS_xList
    
    Node $AllNodes.NodeName 
    {
        xList GenericList
        {
            Url = "https://mkaufmann.sharepoint.com/sites/ALMDays/Lists/MyCustomList"
            Ensure = "Present"
            Title = "My Custom List"
            Description = "A sample generic list"
            Template = "genericList"
            Credentials = $Credential
        }
    }
}

TestListResource -ConfigurationData $ConfigurationData -Credential $Credentials -verbose

Restart-Service Winmgmt -force

Start-DscConfiguration -Path .\TestListResource -Wait -Force -Verbose

#Get-DscConfiguration