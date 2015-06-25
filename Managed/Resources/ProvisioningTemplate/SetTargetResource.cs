namespace SharePointProvisioning.Resources.ProvisioningTemplate
{
    using System;
    using System.IO;
    using System.Management.Automation;
    using System.Net;
    using Microsoft.SharePoint.Client;
    using OfficeDevPnP.Core.Framework.Provisioning.Connectors;
    using OfficeDevPnP.Core.Framework.Provisioning.ObjectHandlers;
    using OfficeDevPnP.Core.Framework.Provisioning.Providers.Xml;
    using OfficeDevPnP.PowerShell.Commands;
    using OfficeDevPnP.PowerShell.Commands.Base;

    [OutputType(typeof(void))]
    [Cmdlet(VerbsCommon.Set, "TargetResource")]
    public class SetTargetResource : SPOWebCmdlet
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

        protected override void ProcessRecord()
        {
            SPOnlineConnection.CurrentConnection = Connection.Instantiate(new Uri(Url), Credentials);

            if (!SelectedWeb.IsPropertyAvailable("Url"))
            {
                ClientContext.Load(SelectedWeb, w => w.Url);
                ClientContext.ExecuteQueryRetry();
            }
            if (!System.IO.Path.IsPathRooted(Path))
            {
                Path = System.IO.Path.Combine(SessionState.Path.CurrentFileSystemLocation.Path, Path);
            }

            var fileInfo = new FileInfo(Path);

            var provider = new XMLFileSystemTemplateProvider(fileInfo.DirectoryName, "");

            var provisioningTemplate = provider.GetTemplate(fileInfo.Name);
            var version = provisioningTemplate.Version;

            if (provisioningTemplate != null)
            {
                var fileSystemConnector = new FileSystemConnector(fileInfo.DirectoryName, "");
                provisioningTemplate.Connector = fileSystemConnector;

                var applyingInformation = new ProvisioningTemplateApplyingInformation();
                applyingInformation.ProgressDelegate = (message, step, total) =>
                {
                    WriteProgress(new ProgressRecord(0, string.Format("Applying template to {0}", SelectedWeb.Url), message) { PercentComplete = (100 / total) * step });
                };

                SelectedWeb.ApplyProvisioningTemplate(provisioningTemplate, applyingInformation);
                // SetPropertyBagValue
                // GetPropertyBagValueString
            }
        }

        
    }
}
