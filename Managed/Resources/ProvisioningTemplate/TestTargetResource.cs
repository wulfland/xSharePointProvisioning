namespace SharePointProvisioning.Resources.ProvisioningTemplate
{
    using System;
    using System.Management.Automation;

    [Cmdlet("Test", "TargetResource")]
    [OutputType(typeof(Boolean))]
    public class TestTargetResource : PSCmdlet
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
    }
}
