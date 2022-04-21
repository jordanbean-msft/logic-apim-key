param appName string
param region string
param environment string
param location string = resourceGroup().location
param publisherName string
param publisherEmail string

module names 'resource-names.bicep' = {
  name: 'resource-names'
  params: {
    appName: appName
    region: region
    env: environment
  }
}

module managedIdentityDeployment 'managed-identity.bicep' = {
  name: 'managed-identity-deployment'
  params: {
    managedIdentityName: names.outputs.managedIdentityName
    location: location
  }
}

module loggingDeployment 'logging.bicep' = {
  name: 'logging-deployment'
  params: {
    location: location
    appInsightsName: names.outputs.appInsightsName
    logAnalyticsWorkspaceName: names.outputs.logAnalyticsWorkspaceName
  }
}

module keyVaultDeployment 'key-vault.bicep' = {
  name: 'key-vault-deployment'
  params: {
    keyVaultName: names.outputs.keyVaultName
    location: location
    userAssignedManagedIdentityName: managedIdentityDeployment.outputs.managedIdentityName
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
  }
}

module storageAccountDeployment 'storage.bicep' = {
  name: 'storage-account-deployment'
  params: {
    location: location
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
    storageAccountName: names.outputs.storageAccountName
  }
}

module apimDeployment 'apim.bicep' = {
  name: 'apim-deployment'
  params: {
    apiManagementServiceName: names.outputs.apiManagementServiceName
    location: location
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

module appServicePlanDeployment 'app-service-plan.bicep' = {
  name: 'app-service-plan-deployment'
  params: {
    location: location
    logicAppAppServicePlanName: names.outputs.logicAppAppServicePlanName
    functionAppAppServicePlanName: names.outputs.functionAppAppServicePlanName
  }
}

module logicAppDeployment 'logic-app.bicep' = {
  name: 'logic-app-deployment'
  params: {
    logicAppName: names.outputs.logicAppName
    appInsightsName: loggingDeployment.outputs.appInsightsName
    appServicePlanName: appServicePlanDeployment.outputs.logicAppAppServicePlanName
    location: location
    storageAccountName: storageAccountDeployment.outputs.storageAccountName
  }
}

module functionDeployment 'func.bicep' = {
  name: 'function-deployment'
  params: {
    appInsightsName: loggingDeployment.outputs.appInsightsName
    appServicePlanName: appServicePlanDeployment.outputs.functionAppServicePlanName
    functionName: names.outputs.functionName
    keyVaultName: keyVaultDeployment.outputs.keyVaultName
    location: location
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
    storageAccountName: storageAccountDeployment.outputs.storageAccountName
    userAssignedManagedIdentityName: managedIdentityDeployment.outputs.managedIdentityName
  }
}
