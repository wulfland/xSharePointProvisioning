using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace ProvisioningTemplate.Tests
{
    public sealed class ResourceHost : IDisposable
    {
        PowerShell powerShell;

        public ResourceHost(string deploymentDirectory)
        {
            var sutAssembly = Path.Combine(deploymentDirectory, "ALIS_xProvisioningTemplate.dll");
            powerShell = PowerShell.Create();
            powerShell.AddCommand("Import-Module").AddArgument(sutAssembly);
            powerShell.Invoke();
        }

        public Collection<PSObject> Execute(string verb, Dictionary<string, string> parameter)
        {
            var script = new StringBuilder();
            script.AppendFormat("{0}-TargetResource", verb);

            BuildParameters(ref script, parameter);

            powerShell.AddScript(script.ToString());

            return InvokeAndRethrowExceptions();
        }

        public Collection<PSObject> ExecuteWithCredentials(string verb, string userName, string password, Dictionary<string, string> parameter)
        {
            var script = new StringBuilder();
            script.AppendFormat("$password='{0}' | ConvertTo-SecureString -asPlainText -Force\n\r", password);
            script.AppendFormat("$user='{0}'\n\r", userName);
            script.Append("$credential = New-Object System.Management.Automation.PSCredential($user,$password)\n\r");
            
            script.AppendFormat("{0}-TargetResource", verb);
            script.AppendFormat(" -Credential $credential");
            
            BuildParameters(ref script, parameter);

            powerShell.AddScript(script.ToString());

            return InvokeAndRethrowExceptions();
        }

        private static void BuildParameters(ref StringBuilder script, Dictionary<string, string> parameter)
        {
            foreach (var para in parameter)
            {
                script.AppendFormat(" -{0}", para.Key);
                if (!string.IsNullOrWhiteSpace(para.Value))
                {
                    script.AppendFormat(" '{0}'", para.Value);
                }
            }
        }

        private Collection<PSObject> InvokeAndRethrowExceptions()
        {
            var result = powerShell.Invoke();

            if (powerShell.HadErrors)
            {
                var error = powerShell.Streams.Error.ReadAll().First();
                throw error.Exception;
            }

            return result;
        }

        public void Dispose()
        {
            powerShell.Dispose();
        }
    }
}
