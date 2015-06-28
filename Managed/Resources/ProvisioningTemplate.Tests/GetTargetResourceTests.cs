using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using ProvisioningTemplate.Tests.Properties;
using SharePointProvisioning.Resources.ProvisioningTemplate;

namespace ProvisioningTemplate.Tests
{
    [TestClass]
    public class GetTargetResourceTests
    {
        [TestMethod]
        [TestCategory(TestCategories.Integration)]
        [DeploymentItem("template.xml")]
        [DeploymentItem("ALIS_xProvisioningTemplate.dll")]
        public void GetTargetResource_returns_Properties_for_OnPrem()
        {
            var template = Path.Combine(TestContext.DeploymentDirectory, "template.xml");

            var sutAssembly = Path.Combine(TestContext.DeploymentDirectory, "ALIS_xProvisioningTemplate.dll");

            using (var powerShell = PowerShell.Create())
            {
                powerShell.AddCommand("Import-Module").AddArgument(sutAssembly);
                powerShell.Invoke();

                powerShell.AddScript("Get-TargetResource " 
                    + "-Url '" + Settings.Default.IntegrationUrl 
                    + "' -Path '" + template 
                    + "' -Verbose");

                var output = powerShell.Invoke();

                Assert.AreEqual(1, output.Count);

                var outputItem = output.First();
                Assert.IsInstanceOfType(outputItem.BaseObject, typeof(Dictionary<string, string>));

                var results = (Dictionary<string, string>)outputItem.BaseObject;
                Assert.AreEqual(Settings.Default.IntegrationUrl, results["Url"]);
                Assert.AreEqual("Absent", results["Ensure"]);
                Assert.AreEqual("0", results["Version"]);
            }
        }

        [TestMethod]
        [TestCategory(TestCategories.Integration)]
        [DeploymentItem("template.xml")]
        [DeploymentItem("ALIS_xProvisioningTemplate.dll")]
        public void GetTargetResource_returns_Properties_for_O365()
        {
            var template = Path.Combine(TestContext.DeploymentDirectory, "template.xml");

            var sutAssembly = Path.Combine(TestContext.DeploymentDirectory, "ALIS_xProvisioningTemplate.dll");

            using (var powerShell = PowerShell.Create())
            {
                powerShell.AddCommand("Import-Module").AddArgument(sutAssembly);
                powerShell.Invoke();

                powerShell.AddScript(
                    "$password = '" + Settings.Default.O365Password + "' | ConvertTo-SecureString -asPlainText -Force;"
                    + "$user = '" + Settings.Default.O365User + "';"
                    + "$credential = New-Object System.Management.Automation.PSCredential($user,$password);"
                    + "Get-TargetResource " 
                    + "-Url '" + Settings.Default.O365Url + "' "
                    + "-Credential $credential "
                    + "-Path '" + template + "' -Verbose;");

                var output = powerShell.Invoke();

                Assert.AreEqual(1, output.Count);

                var outputItem = output.First();
                Assert.IsInstanceOfType(outputItem.BaseObject, typeof(Dictionary<string, string>));

                var results = (Dictionary<string, string>)outputItem.BaseObject;
                Assert.AreEqual(Settings.Default.O365Url, results["Url"]);
                Assert.AreEqual("Absent", results["Ensure"]);
                Assert.AreEqual("0", results["Version"]);
            }
        }

        public TestContext TestContext { get; set; }
    }
}
