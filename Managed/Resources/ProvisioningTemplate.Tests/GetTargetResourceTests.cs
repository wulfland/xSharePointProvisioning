using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using Microsoft.QualityTools.Testing.Fakes;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using ProvisioningTemplate.Tests.Properties;
using SharePointProvisioning.Resources.ProvisioningTemplate;
using OfficeDevPnP.Core.AppModelExtensions;
using Microsoft.SharePoint.Client;
using Microsoft.SharePoint.Client.Fakes;

namespace ProvisioningTemplate.Tests
{
    [TestClass]
    public class GetTargetResourceTests
    {
        [TestMethod]
        [TestCategory(TestCategories.Unit)]
        [DeploymentItem("template.xml")]
        [DeploymentItem("ALIS_xProvisioningTemplate.dll")]
        public void GetTargetResource_can_use_relative_path()
        {
            using (var context = ShimsContext.Create())
            {
                var fakeWeb = new ShimWeb();

                var fakeContext = new ShimClientContext()
                {
                    WebGet = () => fakeWeb,
                    ExecuteQuery = () => { }
                };

                ShimClientContext.AllInstances.ExecuteQuery = (c) => { };

                using (var resourceHost = new ResourceHost(TestContext.DeploymentDirectory))
                {
                    var parameters = new Dictionary<string, string>()
                    {  
                        { "Url", Settings.Default.IntegrationUrl },
                        { "Path", "template.xml" },
                        { "Verbose", null }
                    };

                    var output = resourceHost.Execute("Get", parameters);
                }
            }
        }

        [TestMethod]
        [TestCategory(TestCategories.Integration)]
        [DeploymentItem("template.xml")]
        [DeploymentItem("ALIS_xProvisioningTemplate.dll")]
        public void GetTargetResource_returns_Properties_for_OnPrem()
        {
            var template = Path.Combine(TestContext.DeploymentDirectory, "template.xml");

            using (var resourceHost = new ResourceHost(TestContext.DeploymentDirectory))
            {
                var parameters = new Dictionary<string, string>()
                {  
                    { "Url", Settings.Default.IntegrationUrl },
                    { "Path", template },
                    { "Verbose", null }
                };

                var output = resourceHost.Execute("Get", parameters);

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
