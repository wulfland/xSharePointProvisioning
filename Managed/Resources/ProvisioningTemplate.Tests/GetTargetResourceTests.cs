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

            using (var powerShell = new ResourceHost(TestContext.DeploymentDirectory))
            {
                var parameters = new Dictionary<string, string>()
                {  
                    { "Url", Settings.Default.IntegrationUrl },
                    { "Path", template },
                    { "Verbose", null }
                };

                var output = powerShell.Execute("Get", parameters);

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

            using (var resourceHost = new ResourceHost(TestContext.DeploymentDirectory))
            {
                var parameters = new Dictionary<string, string>()
                {  
                    { "Url", Settings.Default.O365Url },
                    { "Path", template },
                    { "Verbose", null }
                };
                var output = resourceHost.ExecuteWithCredentials("Get", Settings.Default.O365User, Settings.Default.O365Password, parameters);

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
