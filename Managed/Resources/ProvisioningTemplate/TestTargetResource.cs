namespace SharePointProvisioning.Resources.ProvisioningTemplate
{
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using System.IO;
    using System.Management.Automation;
    using Microsoft.SharePoint.Client;
    using OfficeDevPnP.Core.Framework.Provisioning.Providers.Xml;
    using OfficeDevPnP.PowerShell.Commands;
    using OfficeDevPnP.PowerShell.Commands.Base;

    [Cmdlet("Test", "TargetResource")]
    [OutputType(typeof(Boolean))]
    public class TestTargetResource : SPOWebCmdlet
    {
        private string _ensure;

        [Parameter(Mandatory = true)]
        public string Url { get; set; }

        [Parameter(Mandatory = true)]
        public string Path { get; set; }

        [Parameter(Mandatory = false)]
        [ValidateSet("Present", IgnoreCase = true)]
        public string Ensure
        {
            get { return _ensure ?? "Present"; }
            set { _ensure = value; }
        }

        [Parameter(Mandatory = false)]
        public bool Force { get; set; }

        [Parameter(Mandatory = false)]
        public PSCredential Credentials { get; set; }

        protected override void BeginProcessing()
        {
            SPOnlineConnection.CurrentConnection = Connection.Instantiate(new Uri(Url), Credentials);
            base.BeginProcessing();
        }

        protected override void ExecuteCmdlet()
        {
            WriteVerbose("Begin processing of Get-TargetResource...");
           
            if (!System.IO.Path.IsPathRooted(Path))
            {
                Path = System.IO.Path.Combine(SessionState.Path.CurrentFileSystemLocation.Path, Path);
            }

            var fileInfo = new FileInfo(Path);
            var provider = new XMLFileSystemTemplateProvider(fileInfo.DirectoryName, "");

            var provisioningTemplate = provider.GetTemplate(fileInfo.Name);
            var version = SelectedWeb.GetPropertyBagValueString(Global.PropertyBagTagName, "0");
            if (version == provisioningTemplate.Version.ToString())
            {
                WriteVerbose("The state of the template matches the desired state and no action is required.");
                WriteObject(true);
            }
            else
            {
                WriteVerbose(string.Format(
                    "The version ({0}) of the template applied to the site does not match the desired state {1}.", 
                    version,
                    provisioningTemplate.Version));
                WriteObject(false);
            }

            WriteVerbose("End processing of Get-TargetResource...");
        }
    }
}
