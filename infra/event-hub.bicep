param eventHubNamespaceName string
param eventHubName string
param location string
param userAssignedManagedIdentityName string
param logAnalyticsWorkspaceName string
param eventHubSendAuthorizationRuleName string

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' = {
  name: eventHubNamespaceName
  location: location
  properties: {}
  sku: {
    name: 'Standard'
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' = {
  name: '${eventHubNamespace.name}/${eventHubName}'
  properties: {
    messageRetentionInDays: 1
    partitionCount: 2
  }
}

resource eventHubAuthorizationRule 'Microsoft.EventHub/namespaces/eventhubs/authorizationrules@2021-11-01' = {
  name: '${eventHubNamespace.name}/${eventHubName}/${eventHubSendAuthorizationRuleName}'
  properties: {
    rights: [
      'Send'
    ]
  }
}

resource userAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: userAssignedManagedIdentityName
}

var eventHubDataSenderRoleDefinitionId = '2b629674-e913-4c01-ae53-ef4638d8f975'

resource eventHubRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(eventHubDataSenderRoleDefinitionId, userAssignedManagedIdentity.id, eventHub.id)
  scope: eventHub
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', eventHubDataSenderRoleDefinitionId)
    principalId: userAssignedManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource functionAppDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Logging'
  scope: eventHubNamespace
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'ArchiveLogs'
        enabled: true
      }
      {
        category: 'OperationalLogs'
        enabled: true
      }
      {
        category: 'AutoScaleLogs'
        enabled: true
      }
      {
        category: 'KafkaCoordinatorLogs'
        enabled: true
      }
      {
        category: 'KafkaUserErrorLogs'
        enabled: true
      }
      {
        category: 'EventHubVNetConnectionEvent'
        enabled: true
      }
      {
        category: 'CustomerManagedKeyUserLogs'
        enabled: true
      }
      {
        category: 'RuntimeAuditLogs'
        enabled: true
      }
      {
        category: 'ApplicationMetricsLogs'
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

output eventHubNamespace string = eventHubNamespace.name
output eventHubName string = eventHubName
output eventHubSendAuthorizationRuleName string = eventHubSendAuthorizationRuleName
