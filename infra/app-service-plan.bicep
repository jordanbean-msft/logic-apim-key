param location string
param logicAppAppServicePlanName string
param functionAppAppServicePlanName string

resource logicAppAppServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: logicAppAppServicePlanName
  location: location
  sku: {
    name: 'WS1'
    tier: 'WorkflowStandard'
    size: 'WS1'
    family: 'WS'
    capacity: 1
  }
}

resource functionAppServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: functionAppAppServicePlanName
  location: location
  kind: 'web'
  sku: {
    name: 'B1'
    tier: 'Basic'
    size: 'B1'
    family: 'B'
    capacity: 1
  }
}

output logicAppAppServicePlanName string = logicAppAppServicePlan.name
output functionAppServicePlanName string = functionAppServicePlan.name
