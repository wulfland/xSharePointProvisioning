namespace SharePointProvisioning.Resources.ProvisioningTemplate
{
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.Diagnostics;
    using System.IO;
    using System.Management.Automation;
    using System.Net;
    using Microsoft.SharePoint.Client;
    using OfficeDevPnP.Core.Framework.Provisioning.Connectors;
    using OfficeDevPnP.Core.Framework.Provisioning.ObjectHandlers;
    using OfficeDevPnP.Core.Framework.Provisioning.Providers.Xml;
    using OfficeDevPnP.PowerShell.Commands;
    using OfficeDevPnP.PowerShell.Commands.Base;

    [OutputType(typeof(Hashtable))]
    [Cmdlet(VerbsCommon.Get, "TargetResource")]
    public class GetTargetResource : SPOWebCmdlet
    {
        [Parameter(Mandatory = true)]
        public string Url { get; set; }

        [Parameter(Mandatory = true)]
        public string Path { get; set; }

        [Parameter(Mandatory = false)]
        public PSCredential Credentials { get; set; }

        protected override void BeginProcessing()
        {
            SPOnlineConnection.CurrentConnection = Connection.Instantiate(new Uri(Url), Credentials);
            base.BeginProcessing();
        }

        protected override void EndProcessing()
        {
            base.EndProcessing();
        }

        protected override void ExecuteCmdlet()
        {
            WriteVerbose("Begin processing of Get-TargetResource...");
            var currentResourceState = new Dictionary<string, string>();

            currentResourceState.Add("Url", Url);

            if (!System.IO.Path.IsPathRooted(Path))
            {
                Path = System.IO.Path.Combine(SessionState.Path.CurrentFileSystemLocation.Path, Path);
            }

            currentResourceState.Add("Path", Path);

            var fileInfo = new FileInfo(Path);
            var provider = new XMLFileSystemTemplateProvider(fileInfo.DirectoryName, "");

            var provisioningTemplate = provider.GetTemplate(fileInfo.Name);
            var version = SelectedWeb.GetPropertyBagValueString(Global.PropertyBagTagName, "0");
            if (version == "0")
            {
                currentResourceState.Add("Ensure", "Absent");
                currentResourceState.Add("Version", "0");
            }
            else
            {
                currentResourceState.Add("Ensure", "Present");
                currentResourceState.Add("Version", version);
            }

            WriteVerbose("End processing of Get-TargetResource...");

            WriteObject(currentResourceState);
        }

        protected override void ProcessRecord()
        {
            base.ProcessRecord();
        }
    }
}
