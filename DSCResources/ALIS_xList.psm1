function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Url,

        [System.Management.Automation.PSCredential]
		$Credentials
	)
    
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client")
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime")

    $listName = $Url.Substring($Url.LastIndexOf('/') + 1)
    $webUrl = $Url.Substring(0, $Url.LastIndexOf('/')).ToLowerInvariant().Replace("/lists", "")
    $webRelativeUrl = $Url.Replace($webUrl, "")


    $clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($webUrl) 

    if ($Credentials)
    {
        $clientContext.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Credentials.UserName, $Credentials.Password) 
    }

    if (!$clientContext.ServerObjectIsNull.Value) 
    { 
        Write-Verbose "Connected to SharePoint Online site: '$webUrl'"
    } 

    $web = $clientContext.Web
    $clientContext.Load($web)

    try
    {
        $clientContext.ExecuteQuery();

        $listUrl = "$($web.ServerRelativeUrl.TrimEnd('/'))$($Url.Replace($web.Url, ''))"

	    $listFolder = $web.GetFolderByServerRelativeUrl($listUrl)
        $clientContext.Load($listFolder.Properties)

        $clientContext.ExecuteQuery()

        $listId = [guid]($listFolder.Properties["vti_listname"].ToString())
        $list = $web.Lists.GetById($listId);
        $clientContext.Load($list);
        $clientContext.ExecuteQuery();
   

        $Ensure = "Present"
        $title = $list.Title
        $desc = $list.Description
        $template = [System.Enum]::Parse([Microsoft.SharePoint.Client.ListTemplateType], $list.BaseTemplate.ToString())
    }
    catch
    {
        $Ensure = "Absent"
        $title = ""
        $desc = ""
        $template = ""
    }
	
	$returnValue = @{
		Url = $Url
		Ensure = $Ensure
		Title = $title
		Description = $list
		Template = $template
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

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[System.String]
		$Title,

		[System.String]
		$Description,

		[System.String]
		$Template = "genericList",

		[System.Management.Automation.PSCredential]
		$Credentials
	)

	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client")
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime")

    $listName = $Url.Substring($Url.LastIndexOf('/') + 1)
    $webUrl = $Url.Substring(0, $Url.LastIndexOf('/')).ToLowerInvariant().Replace("/lists", "")
    $webRelativeUrl = $Url.Replace($webUrl, "")


    $clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($webUrl) 

    if ($Credentials)
    {
        $clientContext.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Credentials.UserName, $Credentials.Password) 
    }

    if (!$clientContext.ServerObjectIsNull.Value) 
    { 
        Write-Verbose "Connected to SharePoint Online site: '$webUrl'"
    } 

    $web = $clientContext.Web
    $clientContext.Load($web)

    try
    {
        $clientContext.ExecuteQuery();
    }
    catch
    {
        Throw-TerminatingError -errorId ErrConnection -errorMessage "Could not connect to the given URL. Please check your configuration. $($_.Exception.Message)"
        return
    }
    finally
    {
        $clientContext.Dispose()
    }

    $listWebRelativeUrl = $Url.Replace($web.Url, '')
    $listUrl = "$($web.ServerRelativeUrl.TrimEnd('/'))$listWebRelativeUrl"
    
	$listFolder = $web.GetFolderByServerRelativeUrl($listUrl)
    $clientContext.Load($listFolder.Properties)

    try
    {
        $clientContext.ExecuteQuery()

        $listId = [guid]($listFolder.Properties["vti_listname"].ToString())
        $list = $web.Lists.GetById($listId);
        $clientContext.Load($list);
        $clientContext.ExecuteQuery();
   

        if ($Ensure -eq "Absent")
        {
            Write-Verbose "The list dos exist and will be deleted because 'Ensure' is 'Absent'."
            $list.DeleteObject()
            $clientContext.Load($list)
		    $clientContext.ExecuteQuery()
        }
        else
        {
            # Update list
            if ($Title)
            {
                if ($Title -ne $list.Title)
                {
                    $list.Title = $Title
                    $list.Update()
                    Write-Verbose "The title of the list was updated to '$Title'."
                }
            }
            
            if ($Description)
            {
                if ($Description -ne $list.Description)
                {
                    $list.Description = $Description
                    $list.Update()
                    Write-Verbose "The desciption of the list was updated to '$Description'."
                }
            }

            $clientContext.ExecuteQuery()
        }
    }
    catch
    {
        Write-Verbose $_.Exception.Message

        if ($Ensure -eq "Present")
        {
            Write-Verbose "The list dos not exist and will be created because 'Ensure' is 'Present'."

            $listCreationInfo = new-object Microsoft.SharePoint.Client.ListCreationInformation
            $listCreationInfo.TemplateType = [Microsoft.SharePoint.Client.ListTemplateType]::$Template
            $ListCreationInfo.Url = $listWebRelativeUrl.TrimStart('/')
            if (-not $Title)
            {
                $Title = $ListName
            }

            $listCreationInfo.Title = $Title

            if ($Description)
            {
                $listCreationInfo.Description = $Description
            }

            $listCreationInfo.QuickLaunchOption = [Microsoft.SharePoint.Client.QuickLaunchOptions]::on

            $list = $web.Lists.Add($listCreationInfo)
            $clientContext.ExecuteQuery()
        }
        else
        {
            Write-Debug "The list dos not exist and will not be created because 'Ensure' is 'Absent'."
        }
    }
    finally
    {
        $clientContext.Dispose()
    }
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

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		[System.String]
		$Title,

		[System.String]
		$Description,

		[System.String]
		$Template = "genericList",

		[System.Management.Automation.PSCredential]
		$Credentials
	)
    
    $a1 = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client")
    $a2 = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime")

    $listName = $Url.Substring($Url.LastIndexOf('/') + 1)
    $webUrl = $Url.Substring(0, $Url.LastIndexOf('/')).ToLowerInvariant().Replace("/lists", "")
    $webRelativeUrl = $Url.Replace($webUrl, "")

    $clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($webUrl) 

    if ($Credentials)
    {
        $clientContext.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Credentials.UserName, $Credentials.Password) 
    }

    if (!$clientContext.ServerObjectIsNull.Value) 
    { 
        Write-Verbose "Connected to SharePoint Online site: '$webUrl'"
    }

    $web = $clientContext.Web
    $clientContext.Load($web)

    
    try
    {
        $clientContext.ExecuteQuery();
    }
    catch
    {
        Write-Debug $_.Exception.Message
        Write-Verbose "Could not connect to the given URL. Please check your configuration. $($_.Exception.Message)"
        return $false
    }
    finally
    {
        $clientContext.Dispose()
    }

    $listWebRelativeUrl = $Url.Replace($web.Url, '')
    $listUrl = "$($web.ServerRelativeUrl.TrimEnd('/'))$listWebRelativeUrl"
    
	$listFolder = $web.GetFolderByServerRelativeUrl($listUrl)
    $clientContext.Load($listFolder.Properties)

    Write-Debug "Try get listfolder '$listUrl'"

    try
    {
        $clientContext.ExecuteQuery()

        if ($Ensure -eq "Absent")
        {
            Write-Verbose "The ensure state 'Present' does not match the desired state 'Absent'."
            return $false
        }

        $listId = [guid]($listFolder.Properties["vti_listname"].ToString())
        $list = $web.Lists.GetById($listId);
        $clientContext.Load($list);
        $clientContext.ExecuteQuery();


        if ($Title)
        {
            if ($Title -ne $list.Title)
            {
                Write-Verbose "The value of property 'Title' is '$($list.Title)' and does not match the desired state '$Title'."
                return $false
            }
        }

        if ($Description)
        {
            if ($Description -ne $list.Description)
            {
                Write-Verbose "The value of property 'Description' is '$($list.Description)' and does not match the desired state '$Description'."
                return $false
            }
        }

        return $true

    }
    catch
    {
        if ($Ensure -eq "Present")
        {
            Write-Verbose "The ensure state 'Absent' does not match the desired state 'Present'."
            return $false
        }

        return $true
    }
    finally
    {
        $clientContext.Dispose()
    }
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

