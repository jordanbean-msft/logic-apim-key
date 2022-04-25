[CmdletBinding()]
param (
  [Parameter()]
  [string]
  $ManagedIdentityName
)

$serviceManagementScope = "https://management.azure.com/user_impersonation"

Import-Module AzureAD -UseWindowsPowerShell

Connect-AzureAD

$ManagedIdentityName = 'mi-logicApimKey-ussc-demo'

$managedIdentityServicePrincipal = (Get-AzureADServicePrincipal -Filter "DisplayName eq '$ManagedIdentityName'")

$serviceManagementServicePrincipal = (Get-AzureADServicePrincipal -Filter "DisplayName eq 'Windows Azure Service Management API'")

$AzureMgmtAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
$AzureMgmtAccess.ResourceAppId = $serviceManagementServicePrincipal.AppId

$AzureSvcMgmt = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "41094075-9dad-400e-a0bd-54e686782033", "Scope"
$AzureMgmtAccess.ResourceAccess = [Array](
  {
    Id = "41094075-9dad-400e-a0bd-54e686782033";
    Type = "Scope"
  }
)

Set-AzureAdApplication -Id $managedIdentityServicePrincipal.Id -RequiredResourceAccess @($azureMgmtAccess)