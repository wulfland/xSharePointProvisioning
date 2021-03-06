function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Title,

		[parameter(Mandatory = $true)]
		[System.String]
		$Url,

        [System.Management.Automation.PSCredential]
		$Credentials
	)

	Load-Assemblies

    $listName = $Url.Substring($Url.LastIndexOf('/') + 1)
    $webUrl = $Url.Substring(0, $Url.LastIndexOf('/')).ToLowerInvariant().Replace("/lists", "")
    $Properties = @{}

    $clientContext = New-ClientContext -WebUrl $webUrl -Credentials $Credentials

    try
    {
        $web = $clientContext.Web
        $clientContext.Load($web)

        $clientContext.ExecuteQuery();

        $list = Get-List -Web $web -Url $Url

        $item = Get-ListItem -List $list -Title $Title

        if ($item)
        {
            $Ensure = "Present"

            foreach ($key in $item.FieldValues.Keys)
            {
                $Properties[$key] = $item.FieldValues[$key]
            } 
        }
        else
        {
            $Ensure = "Absent"
        }
    }
    catch
    {
        $Ensure = "Absent"
    }
    finally
    {
        $clientContext.Dispose()
    }

    #$AdvancedProperties = New-CimInstance -ClassName MSFT_KeyValuePair -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property $Properties -ClientOnly

	$returnValue = @{
		Title = $Title
		Url = $Url
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
		$Title,

		[parameter(Mandatory = $true)]
		[System.String]
		$Url,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		#[System.Collections.Hashtable]
        [Microsoft.Management.Infrastructure.CimInstance[]]
		$Properties,

		[System.Management.Automation.PSCredential]
		$Credentials
	)

	Load-Assemblies

    $listName = $Url.Substring($Url.LastIndexOf('/') + 1)
    $webUrl = $Url.Substring(0, $Url.LastIndexOf('/')).ToLowerInvariant().Replace("/lists", "")

    $clientContext = New-ClientContext -WebUrl $webUrl -Credentials $Credentials

    try
    {
        $web = $clientContext.Web
        $clientContext.Load($web)

        $clientContext.ExecuteQuery();

        $list = Get-List -Web $web -Url $Url

        $item = Get-ListItem -List $list -Title $Title

        if ($item)
        {
            if ($Ensure -eq "Absent")
            {
                Write-Verbose "Remove list item with title '$Title'."
                $item.DeleteObject()
                $clientContext.ExecuteQuery();
            }
            else
            {
                Write-Verbose "Update list item...."
                foreach ($property in $Properties)
                {
                    Write-Verbose "$($property.Key): $($property.Value)"

                    $actual = $item[$property.Key]
                    $desired = $property.Value
                    
                    if ($actual -ne $desired)
                    {
                        Write-Verbose "Property '$($property.Key)' has value '$actual' and will be updated to '$desired'."
                        $item[$property.Key] = $desired
                        $item.Update()
                        $clientContext.ExecuteQuery()
                    }
                } 

                Write-Verbose "Item updated successfully."
            }
        }
        else
        {
            if ($Ensure -eq "Present")
            {
                New-ListItem -List $list -Title $Title -ClientContext $clientContext -Properties $Properties
            }
        }
        
    }
    catch
    {
        Throw-TerminatingError -errorId InvalidOperation -errorMessage $_.Exception.Message -errorCategory InvalidArgument
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
		$Title,

		[parameter(Mandatory = $true)]
		[System.String]
		$Url,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present",

		#[System.Collections.Hashtable]
        [Microsoft.Management.Infrastructure.CimInstance[]]
		$Properties,

		[System.Management.Automation.PSCredential]
		$Credentials
	)

	$state = Get-TargetResource -Title $Title -Url $Url -Credentials $Credentials

    foreach ($property in $Properties)
    {
        Write-Verbose "$($property.Key): $($property.Value)"
    }

    if ($Ensure -ne $state["Ensure"])
    {
        Write-Verbose "The ensure state '$($state["Ensure"])' does not match the desired state '$Ensure'."
        return $false
    }


    foreach ($property in $Properties)
    {
        Write-Verbose "$($property.Key): $($property.Value)"

        $actual = $state["Properties"][$property.Key]
        $desired = $Property.Value

        if ($actual -ne $desired)
        {
            Write-Verbose "The value of field '$($property.Name)' is '$actual' does not match the desired state '$desired'."
            return $false
        }
    }

    return $true
}

function New-ListItem
{
    [CmdletBinding()]
	param
	(		
		[Parameter(Mandatory=$true, Position=1)]
		[Microsoft.SharePoint.Client.List]$List, 

        [Parameter(Mandatory=$true, Position=2)]
		[string]$Title, 
		
		[Parameter(Mandatory=$true, Position=3)]
		[Microsoft.Management.Infrastructure.CimInstance[]]$Properties,

        [Parameter(Mandatory=$true, Position=4)]
        [Microsoft.SharePoint.Client.ClientContext]
        $ClientContext
	)

    $listItemCreationInformation = New-Object Microsoft.SharePoint.Client.ListItemCreationInformation
    $item = $List.AddItem($listItemCreationInformation)                
    $item["Title"] = $Title  

    foreach ($property in $Properties) 
    {
        Write-Verbose "$($property.Key): $($property.Value)"
        $fieldName = $property.Key
        $fieldValue = $property.Value

        Write-Verbose "Set property '$fieldName' to value '$fieldValue'..."
        $item[$fieldName] = $fieldValue
    }
                     
    $item.Update()
    $ClientContext.Load($item) 
    $ClientContext.ExecuteQuery()

    Write-Verbose "ListItem '$Title' created successfully."
}

function Get-ListItem
{
    [CmdletBinding()]
    [OutputType([Microsoft.SharePoint.Client.ListItem])]
	param
	(		
		[Parameter(Mandatory=$true, Position=1)]
		[Microsoft.SharePoint.Client.List]$List, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[System.String]$Title
	)
                  
    $camlQuery = New-Object Microsoft.SharePoint.Client.CamlQuery
    $camlQuery.ViewXml = "<View><Query><Where><Eq><FieldRef Name='Title' /><Value Type='Text'>$Title</Value></Eq></Where></Query></View>";

    $result = $List.GetItems($camlQuery)

    $clientContext.Load($result)
    $clientContext.ExecuteQuery()

    if ($result.Count -ge 1)
    {
        return $result[0]
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
    $list = $web.Lists.GetById($listId)
    $clientContext.Load($list)
    $clientContext.ExecuteQuery()

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

