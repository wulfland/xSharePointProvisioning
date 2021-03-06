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
		$FieldXml,

        [System.Management.Automation.PSCredential]
		$Credentials
	)

    Load-Assemblies

    $listName = $Url.Substring($Url.LastIndexOf('/') + 1)
    $webUrl = $Url.Substring(0, $Url.LastIndexOf('/')).ToLowerInvariant().Replace("/lists", "")
    $webRelativeUrl = $Url.Replace($webUrl, "")
    
    [xml]$xml = $FieldXml
    $fieldInternalName = $xml.Field.Name
	$fieldDisplayName = $xml.Field.DisplayName

    $clientContext = New-ClientContext -WebUrl $webUrl -Credentials $Credentials

    try
    {
        $web = $clientContext.Web
        $clientContext.Load($web)

        $clientContext.ExecuteQuery();

        $list = Get-List -Web $web -Url $Url

        $fields = $list.Fields
        $clientContext.Load($fields)
        $clientContext.ExecuteQuery()

        # We have to check against the InternalName of a field
	    # because there could be several fields with the same
	    # DisplayName value (e.g. Name)
        if (Test-Field $fields $fieldInternalName)
        {
		    $_ensure = "Present"
        }
        else
        {
		    $_ensure = "Absent"
        }
    }
    catch
    {
        Write-Warning $_.Exception.Message
        $_ensure = "Absent"
    }
    finally
    {
        $clientContext.Dispose()
    }


	$returnValue = @{
		Url = $Url
		Ensure = $_ensure
		FieldXml = $FieldXml
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

        [parameter(Mandatory = $true)]
		[System.String]
		$FieldXml,

		[System.Management.Automation.PSCredential]
		$Credentials
	)

	Load-Assemblies

    $listName = $Url.Substring($Url.LastIndexOf('/') + 1)
    $webUrl = $Url.Substring(0, $Url.LastIndexOf('/')).ToLowerInvariant().Replace("/lists", "")
    $webRelativeUrl = $Url.Replace($webUrl, "")
    
    $fieldInternalName = ([xml]$fieldXML).Field.Name
	$fieldDisplayName = ([xml]$fieldXML).Field.DisplayName

    $clientContext = New-ClientContext -WebUrl $webUrl -Credentials $Credentials

    try
    {
        $web = $clientContext.Web
        $clientContext.Load($web)

        $clientContext.ExecuteQuery();

        $list = Get-List -Web $web -Url $Url

        $fields = $list.Fields
        $clientContext.Load($fields)
        $clientContext.ExecuteQuery()

        # We have to check against the InternalName of a field
	    # because there could be several fields with the same
	    # DisplayName value (e.g. Name)
        if (!(Test-Field $fields $fieldInternalName))
        {
		    if ($Ensure = "Present")
            {
                # Add the field
                Add-Field -Web $web -List $list -FieldXml $FieldXml
            }
        }
        else
        {
		    if ($Ensure = "Absent")
            {
                # Remove the field
                Remove-Field -Web $web -List $list -FieldXml $FieldXml
            }
        }
    }
    catch
    {
        Throw-TerminatingError -errorId "GeneralError" -errorMessage "Error setting target resource. $($_.Exception.Message)"
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

        [parameter(Mandatory = $true)]
		[System.String]
		$FieldXml,

		[System.Management.Automation.PSCredential]
		$Credentials
	)

	$current = Get-TargetResource -Url $Url -Credentials $Credentials -FieldXml $FieldXml

    Write-Verbose "The ensure state of field '$FieldXml' is '$($current["Ensure"])'. The desired state is '$Ensure'."

    $result = $current["Ensure"] -eq $Ensure

    $result
}

function Add-Field
{
    [CmdletBinding()]
	param
	(		
		[Parameter(Mandatory=$true, Position=1)]
		[Microsoft.SharePoint.Client.Web]$Web, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[Microsoft.SharePoint.Client.List]$List,

        [Parameter(Mandatory=$true, Position=3)]
		[xml]$FieldXML
	)

    # Without the AddFieldInternalNameHint, SP would not honor the Name attribute
	# but instead use the DisplayName attribute to generate the InternalName
	$options = [Microsoft.SharePoint.Client.AddFieldOptions] "AddToAllContentTypes, AddFieldInternalNameHint"
    $field = $List.Fields.AddFieldAsXml($FieldXML.InnerXml, $true, $options);
    $List.Update()
    $List.ParentWeb.Context.ExecuteQuery()

	if($field.Title -ne $fieldXML.Field.DisplayName)
	{
		$field.Title = $fieldXML.Field.DisplayName
		$field.Update()
		$clientContext.ExecuteQuery()
	}
        
	Write-Verbose "Field '$($fieldXML.Field.Name)' added as '$($fieldXML.Field.DisplayName)' to list '$($List.Title)'"
}

function Remove-Field
{
    [CmdletBinding()]
	param
	(		
		[Parameter(Mandatory=$true, Position=1)]
		[Microsoft.SharePoint.Client.Web]$Web, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[Microsoft.SharePoint.Client.List]$List,

        [Parameter(Mandatory=$true, Position=3)]
		[xml]$FieldXML
	)

    # Without the AddFieldInternalNameHint, SP would not honor the Name attribute
	# but instead use the DisplayName attribute to generate the InternalName
	$options = [Microsoft.SharePoint.Client.AddFieldOptions] "AddToAllContentTypes, AddFieldInternalNameHint"
    
    $field = $List.Fields.GetByInternalNameOrTitle($fieldXML.Field.Name)
    $field.DeleteObject()
    $List.ParentWeb.Context.ExecuteQuery()
        
	Write-Verbose "Field '$($fieldXML.Field.Name)' removed from list '$($List.Title)'"
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

function Test-Field
{
	[CmdletBinding()]
    [OutputType([bool])]
	param
	(		
		[Parameter(Mandatory=$true, Position=1)]
		[Microsoft.SharePoint.Client.FieldCollection] $fields, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName
	)
	
    $fieldNames = $fields.GetEnumerator() | select -ExpandProperty InternalName
    $exists = ($fieldNames -contains $fieldName)
	
    return $exists
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

