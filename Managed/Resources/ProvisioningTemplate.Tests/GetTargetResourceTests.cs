using System.Collections;
using System.Collections.Generic;
using System.IO;
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
        public void GetTargetResource_returnsProperties()
        {
            var template = Path.Combine(TestContext.DeploymentDirectory, "template.xml");


            var sut = new GetTargetResource();
            sut.Path = template;
            sut.Url = Settings.Default.IntegrationUrl;


            IEnumerator result = sut.Invoke().GetEnumerator();
            
            Assert.IsTrue(result.MoveNext());

            Assert.IsTrue(result.Current is Dictionary<string, string>);

        }

        public TestContext TestContext { get; set; }
    }
}
