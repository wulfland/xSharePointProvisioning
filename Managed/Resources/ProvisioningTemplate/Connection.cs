namespace SharePointProvisioning.Resources.ProvisioningTemplate
{
    using System;
    using System.Management.Automation;
    using System.Net;
    using Microsoft.SharePoint.Client;
    using OfficeDevPnP.Core;
    using OfficeDevPnP.PowerShell.Commands.Base;
    using OfficeDevPnP.PowerShell.Commands.Enums;

    internal static class Connection
    {
        internal static SPOnlineConnection Instantiate(Uri url, PSCredential credentials, int minimalHealthScore = -1, int retryCount = -1, int retryWait = 5, int requestTimeout = 180000)
        {
            var context = new ClientContext(url.AbsoluteUri);
            context.ApplicationName = "xProvisioningTemplate";
            context.RequestTimeout = requestTimeout;

            if (credentials != null)
            {
                try
                {
                    var onlineCredentials = new SharePointOnlineCredentials(credentials.UserName, credentials.Password);
                    context.Credentials = onlineCredentials;

                    try
                    {
                        context.ExecuteQueryRetry();
                    }
                    catch (ClientRequestException)
                    {
                        context.Credentials = new NetworkCredential(credentials.UserName, credentials.Password);
                    }
                    catch (ServerException)
                    {
                        context.Credentials = new NetworkCredential(credentials.UserName, credentials.Password);
                    }
                }
                catch (ArgumentException)
                {
                    // OnPrem?
                    context.Credentials = new NetworkCredential(credentials.UserName, credentials.Password);
                    try
                    {
                        context.ExecuteQueryRetry();
                    }
                    catch (ClientRequestException ex)
                    {
                        throw new Exception("Error establishing a connection", ex);
                    }
                    catch (ServerException ex)
                    {
                        throw new Exception("Error establishing a connection", ex);
                    }
                }

            }
            else
            {
                if (credentials != null)
                {
                    context.Credentials = new NetworkCredential(credentials.UserName, credentials.Password);
                }
            }

            var connectionType = ConnectionType.OnPrem;
            if (url.Host.ToUpperInvariant().EndsWith("SHAREPOINT.COM"))
            {
                connectionType = ConnectionType.O365;
            }

            return new SPOnlineConnection(context, connectionType, minimalHealthScore, retryCount, retryWait, credentials, url.ToString());
        }
    }
}
