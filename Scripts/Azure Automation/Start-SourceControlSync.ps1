param(
    [Parameter(mandatory=$false)]
    [string]$connectionName = "AzureRunAsConnection",

    [Parameter(mandatory=$false)]
    [string]$automationAccountName = "SandboxGovernanceAutomationAccount",

    [Parameter(mandatory=$false)]
    [string]$resourceGroupName = "SandboxGovernance"
)
$errorActionPreference = "stop"

# Import Modules
Import-Module az.Accounts
Import-Module az.Automation

# Get Azure Run As Connection Name
$connectionName = "AzureRunAsConnection"
# Get the Service Principal connection details for the Connection name
$servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         

# Logging in to Azure AD with Service Principal
"Logging in to Azure AD..."
Connect-AzAccount -TenantId $servicePrincipalConnection.TenantId `
    -ApplicationId $servicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint

# Get Automation Account Object
$automationAccount = Get-AzAutomationAccount -Name $automationAccountName -ResourceGroupName $resourceGroupName 

#start source control sync job
$sc = Get-AzAutomationSourceControl -AutomationAccountName $automationAccount.AutomationAccountName -ResourceGroupName $automationAccount.ResourceGroupName 
$syncJob = Start-AzAutomationSourceControlSyncJob -SourceControlName $sc.Name -AutomationAccountName $automationAccount.AutomationAccountName -ResourceGroupName $automationAccount.ResourceGroupName 
$syncJobResult = Get-AzAutomationSourceControlSyncJob -SourceControlName $sc.Name -JobId $syncJob.SourceControlSyncJobId -AutomationAccountName $automationAccount.AutomationAccountName -ResourceGroupName $automationAccount.ResourceGroupName
# Get Sync Job Status, wait for completion 
while ($syncJobResult.ProvisioningState -eq 'New' -or $syncJobResult.ProvisioningState -eq 'Running'){
    $syncJobResult = Get-AzAutomationSourceControlSyncJob -SourceControlName $sc.Name -JobId $syncJob.SourceControlSyncJobId -AutomationAccountName $automationAccount.AutomationAccountName -ResourceGroupName $automationAccount.ResourceGroupName
    write-output "waiting for sync job to complete"
    start-sleep -Seconds 3
}
$syncJobResult
