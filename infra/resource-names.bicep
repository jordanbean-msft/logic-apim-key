param appName string
param region string
param env string

output managedIdentityName string = 'mi-${appName}-${region}-${env}'
output appInsightsName string = 'ai-${appName}-${region}-${env}'
output logAnalyticsWorkspaceName string = 'la-${appName}-${region}-${env}'
output keyVaultName string = 'kv${appName}${region}${env}'
output storageAccountName string = toLower('sa${appName}${region}${env}')
output logicAppName string = 'logic-${appName}-${region}-${env}'
output apiManagementServiceName string = 'apim-${appName}-${region}-${env}'
output functionName string = 'func-${appName}-${region}-${env}'
output functionAppAppServicePlanName string = 'asp-func-${appName}-${region}-${env}'
output logicAppAppServicePlanName string = 'asp-logic-${appName}-${region}-${env}'
