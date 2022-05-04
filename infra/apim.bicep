param apiManagementServiceName string
param location string
param publisherEmail string
param publisherName string
param logAnalyticsWorkspaceName string
param appInsightsName string
param userAssignedManagedIdentityName string
param eventHubNamespaceName string
param eventHubName string
param eventHubSendAuthorizationRuleName string
param tenantId string
param apiAppIdUri string

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource userAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: userAssignedManagedIdentityName
}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' existing = {
  name: eventHubNamespaceName
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' existing = {
  name: '${eventHubNamespace.name}/${eventHubName}'
}

resource eventHubSendAuthorizationRule 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2021-11-01' existing = {
  name: '${eventHubNamespace.name}/${eventHubName}/${eventHubSendAuthorizationRuleName}'
}

resource apiManagementService 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: apiManagementServiceName
  location: location
  sku: {
    name: 'Developer'
    capacity: 1
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedManagedIdentity.id}': {}
    }
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
  resource eventHubLogger 'loggers@2021-08-01' = {
    name: 'eventHubLogger'
    properties: {
      loggerType: 'azureEventHub'
      resourceId: eventHub.id
      credentials: {
        name: eventHubNamespaceName
        //connectionString: 'Endpoint=sb://${eventHubNamespaceName}.servicebus.windows.net/;Authentication=Managed Identity;EntityPath=${eventHubName}'
        connectionString: eventHubSendAuthorizationRule.listKeys().primaryConnectionString
      }
    }
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

resource echoApiAllOperationsPolicy 'Microsoft.ApiManagement/service/apis/policies@2021-08-01' = {
  name: '${apiManagementService.name}/echo-api/policy'
  properties: {
    format: 'xml'
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized" require-expiration-time="true" require-scheme="Bearer" require-signed-tokens="true">\r\n            <openid-config url="https://login.microsoftonline.com/${tenantId}/v2.0/.well-known/openid-configuration" />\r\n            <audiences>\r\n                <audience>${apiAppIdUri}</audience>\r\n            </audiences>\r\n            <issuers>\r\n                <issuer>https://sts.windows.net/${tenantId}/</issuer>\r\n            </issuers>\r\n        </validate-jwt>\r\n    <set-variable name="message-id" value="@(Guid.NewGuid())" />\r\n    <log-to-eventhub logger-id="eventHubLogger" partition-id="0">@{\r\n          var requestLine = string.Format("{0} {1} HTTP/1.1\\r\\n",\r\n                                                      context.Request.Method,\r\n                                                      context.Request.Url.Path + context.Request.Url.QueryString);\r\n\r\n          var body = context.Request.Body?.As&lt;string&gt;(true);\r\n          if (body != null &amp;&amp; body.Length &gt; 1024)\r\n          {\r\n              body = body.Substring(0, 1024);\r\n          }\r\n\r\n          var headers = context.Request.Headers\r\n                               .Where(h =&gt; h.Key != "Authorization" &amp;&amp; h.Key != "Ocp-Apim-Subscription-Key")\r\n                               .Select(h =&gt; string.Format("{0}: {1}", h.Key, String.Join(", ", h.Value)))\r\n                               .ToArray&lt;string&gt;();\r\n\r\n          var headerString = (headers.Any()) ? string.Join("\\r\\n", headers) + "\\r\\n" : string.Empty;\r\n\r\n            var jwt = context.Request.Headers.GetValueOrDefault("Authorization",string.Empty).Split(\' \').Last().AsJwt();\r\n\r\n            var appId = jwt.Claims.GetValueOrDefault("appid", string.Empty);\r\n\r\n                      return "request:"   + context.Variables["message-id"] + "\\n"\r\n                              + requestLine + headerString + "\\r\\n" + body + "\\n"\r\n                              + "appId:" + appId;\r\n      }</log-to-eventhub>\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n    <log-to-eventhub logger-id="eventHubLogger" partition-id="0">@{\r\n          var statusLine = string.Format("HTTP/1.1 {0} {1}\\r\\n",\r\n                                              context.Response.StatusCode,\r\n                                              context.Response.StatusReason);\r\n\r\n          var body = context.Response.Body?.As&lt;string&gt;(true);\r\n          if (body != null &amp;&amp; body.Length &gt; 1024)\r\n          {\r\n              body = body.Substring(0, 1024);\r\n          }\r\n\r\n          var headers = context.Response.Headers\r\n                                          .Select(h =&gt; string.Format("{0}: {1}", h.Key, String.Join(", ", h.Value)))\r\n                                          .ToArray&lt;string&gt;();\r\n\r\n          var headerString = (headers.Any()) ? string.Join("\\r\\n", headers) + "\\r\\n" : string.Empty;\r\n\r\n            return "response:"  + context.Variables["message-id"] + "\\n"\r\n                              + statusLine + headerString + "\\r\\n" + body + "\\n";\r\n}</log-to-eventhub>\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
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
