targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

var tags = { 'azd-env-name': environmentName }
var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Container apps host (including container registry)
module containerApps 'core/host/container-apps.bicep' = {
  name: 'container-apps'
  scope: resourceGroup
  params: {
    name: 'app'
    containerAppsEnvironmentName: '${abbrs.appManagedEnvironments}${resourceToken}'
    containerRegistryName: '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsWorkspaceName
  }
}

// Monitor application with Azure Monitor
module monitoring 'core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    logAnalyticsName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: '${abbrs.portalDashboards}${resourceToken}'
  }
}

// this launches a redis instance inside of the ACA env
module redis 'core/host/container-app.bicep' = {
  name: 'redis'
  scope: resourceGroup
  params: {
    name: 'redis'
    location: location
    tags: tags
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    serviceType: 'redis'
  }
}

// publisher
module publisher 'core/host/container-app.bicep' = {
  name: 'publisher'
  scope: resourceGroup
  params: {
    name: 'publisher'
    location: location
    tags: union(tags, { 'azd-service-name': 'publisher' })
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    identityName: '${abbrs.managedIdentityUserAssignedIdentities}publisher-${resourceToken}'
  }
}

// subscriber
module subscriber 'core/host/container-app.bicep' = {
  name: 'subscriber'
  scope: resourceGroup
  params: {
    name: 'subscriber'
    location: location
    tags: union(tags, { 'azd-service-name': 'subscriber' })
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    identityName: '${abbrs.managedIdentityUserAssignedIdentities}subscriber-${resourceToken}'
  }
}

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerApps.outputs.registryLoginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerApps.outputs.registryName
output ACA_ENVIRONMENT_NAME string = containerApps.outputs.environmentName
