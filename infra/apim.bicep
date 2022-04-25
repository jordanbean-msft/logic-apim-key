param apiManagementServiceName string
param location string
param publisherEmail string
param publisherName string
param logAnalyticsWorkspaceName string
param appInsightsName string
param userAssignedManagedIdentityName string

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource apiManagementService 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: apiManagementServiceName
  location: location
  sku: {
    name: 'Developer'
    capacity: 1
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
  resource appInsightsLogger 'loggers@2021-08-01' = {
    name: 'appInsightsLogger'
    properties: {
      loggerType: 'applicationInsights'
      credentials: {
        instrumentationKey: appInsights.properties.InstrumentationKey
      }
    }
  }
  resource appInsightsDiagnosticLogs 'diagnostics@2021-08-01' = {
    name: 'applicationinsights'
    properties: {
      loggerId: appInsightsLogger.id
      alwaysLog: 'allErrors'
      sampling: {
        percentage: 100
        samplingType: 'fixed'
      }
      httpCorrelationProtocol: 'W3C'
      logClientIp: true
      operationNameFormat: 'Url'
      verbosity: 'verbose'
      frontend: {
        request: {
          body: {
            bytes: 100
          }
          headers: [
            'Content-Type'
            'User-Agent'
          ]
        }
        response: {}
      }
      backend: {
        request: {
          body: {
            bytes: 100
          }
          headers: [
            'Content-Type'
            'User-Agent'
          ]
        }
        response: {}
      }
    }
  }
}

resource userAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: userAssignedManagedIdentityName
}

var apiManagementServiceContributorRoleDefinitionId = '312a565d-c81f-4fd8-895a-4e21e48d571c'

resource apimRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(apiManagementServiceContributorRoleDefinitionId, userAssignedManagedIdentity.id, apiManagementService.id)
  scope: apiManagementService
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', apiManagementServiceContributorRoleDefinitionId)
    principalId: userAssignedManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource functionAppDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Logging'
  scope: apiManagementService
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
      }
      {
        category: 'WebSocketConnectionLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output apimName string = apiManagementService.name
