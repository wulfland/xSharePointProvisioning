function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Url,

		[parameter(Mandatory = $true)]
		[System.String]
		$SourcePath,

        [System.Management.Automation.PSCredential]
		$Credentials
	)

	Load-Assemblies

    
    $urlList = Parse-FileUri $Url
    $clientContext = Test-WebUrl -UrlsToTest $urlList -Credentials $Credentials

    if (-not $clientContext)
    {
        Throw-TerminatingError -errorId "URL" -errorMessage "Cannot connect to the site. Please check the url." -errorCategory InvalidArgument
    }

    try
    {
        $web = $clientContext.Web
        $clientContext.Load($web)

        $clientContext.ExecuteQuery();

        $serverRelativeUrl = "$($web.ServerRelativeUrl.TrimEnd('/'))$($Url.Replace($web.Url, ''))"

        $file = $web.GetFileByServerRelativeUrl($serverRelativeUrl)

        $clientContext.Load($file)
        $clientContext.ExecuteQuery();

        if ($file.Exists)
        {
            $Ensure = "Present"
            $Properties = $file.Properties
        }
        else
        {
            $Ensure = "Absent"
            $Properties = @{}
        }
    }
    catch
    {
        $Ensure = "Absent"
        $Properties = @{}
    }
    finally
    {
        $clientContext.Dispose()
    }

	$returnValue = @{
		Url = $Url
		SourcePath = $SourcePath
		Ensure = $Ensure
		Properties = $Properties
	}

	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Url,

		[parameter(Mandatory = $true)]
		[System.String]
		$SourcePath,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[System.Collections.Hashtable]
		$Properties,

		[System.Management.Automation.PSCredential]
		$Credentials
	)

	#Write-Verbose "Use this cmdlet to deliver information about command processing."

	#Write-Debug "Use this cmdlet to write debug information while troubleshooting."

	#Include this line if the resource requires a system reboot.
	#$global:DSCMachineStatus = 1


}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Url,

		[parameter(Mandatory = $true)]
		[System.String]
		$SourcePath,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[System.Collections.Hashtable]
		$Properties,

		[System.Management.Automation.PSCredential]
		$Credentials
	)

	$current = Get-TargetResource -SourcePath $SourcePath -Url $Url -Credentials $Credentials

    $result = $current["Ensure"] -eq $Ensure

    $result
}

function Parse-FileUri
{
    [CmdletBinding()]
    [OutputType([String[]])]
	param
	(		
		[Parameter(Mandatory=$true, Position=1)]
		[Uri]$fileUri
	)

    $result = @()
    $urlSplit = $fileUri.AbsolutePath.Split(@('/'), [StringSplitOptions]::RemoveEmptyEntries)

    for ($i = 0; $i -le $urlSplit.Count - 2; $i++) 
    {
        if ($i -eq 0)
        {
            $result += "$($fileUri.Scheme)://$($fileUri.Host)/$($urlSplit[$i])"
        }
        else
        {
            $result += "$($result[$i - 1])/$($urlSplit[$i])"
        }
    }

    $result
}

function Test-WebUrl
{
    [CmdletBinding()]
    [OutputType([Microsoft.SharePoint.Client.ClientContext])]
	param
	(		
		[Parameter(Mandatory=$true)]
		[String[]]$UrlsToTest,

        [System.Management.Automation.PSCredential]
		$Credentials
	)

    $urlsToTest = $urlsToTest | Sort-Object -Descending
    $validRelativeUrls = @()

    foreach($path in $urlsToTest)
    {
        try
        {
            $clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($path)

            if ($Credentials)
            {
                $clientContext.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Credentials.UserName, $Credentials.Password) 
            }

            $clientContext.ExecuteQuery()
            
            return $clientContext
        }
        catch
        {
        }
    }

    return $null
}

function Get-List
{
    [CmdletBinding()]
    [OutputType([Microsoft.SharePoint.Client.List])]
	param
	(		
		[Parameter(Mandatory=$true, Position=1)]
		[Microsoft.SharePoint.Client.Web]$Web, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $Url
	)

    $listUrl = "$($web.ServerRelativeUrl.TrimEnd('/'))$($Url.Replace($web.Url, ''))"

	$listFolder = $web.GetFolderByServerRelativeUrl($listUrl)
    $Web.Context.Load($listFolder.Properties)

    $Web.Context.ExecuteQuery()

    $listId = [guid]($listFolder.Properties["vti_listname"].ToString())
    $list = $web.Lists.GetById($listId);
    $clientContext.Load($list);
    $clientContext.ExecuteQuery();

    return $list
}

function New-ClientContext
{
    [CmdletBinding()]
	[OutputType([Microsoft.SharePoint.Client.ClientContext])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$WebUrl,
        [PSCredential]
        $Credentials
	)

    $clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($webUrl) 

    if ($Credentials)
    {
        $clientContext.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Credentials.UserName, $Credentials.Password) 
    }

    if (!$clientContext.ServerObjectIsNull.Value) 
    { 
        Write-Verbose "Connected to SharePoint Online site: '$webUrl'"
    } 

    $clientContext
}

function Load-Assemblies
{
    # suppress output
    $assembly1 = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client")
    $assembly2 = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime")

    Write-Verbose "Assemblies loaded."
}

function Throw-TerminatingError
{
    [CmdletBinding()]
    param
    (
        [string]$errorId,
        [string]$errorMessage,
        [System.Management.Automation.ErrorCategory]$errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
    )

    $exception = New-Object System.InvalidOperationException $errorMessage 
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

    $PSCmdlet.ThrowTerminatingError($errorRecord);
}

Export-ModuleMember -Function *-TargetResource

