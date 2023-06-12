targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Specifies if the subscriber app exists')
param subscriberAppExists bool = false

@description('Specifies if the publisher app exists')
param publisherAppExists bool = false

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

// identities
module publisherIdentity 'core/security/user-assigned-identity.bicep' = {
  scope: resourceGroup
  name: 'publisherIdentity'
  params: {
    identityName: '${abbrs.managedIdentityUserAssignedIdentities}publisher-${resourceToken}'
    location: location
  }
}

module subscriberIdentity 'core/security/user-assigned-identity.bicep' = {
  scope: resourceGroup
  name: 'subscriberIdentity'
  params: {
    identityName: '${abbrs.managedIdentityUserAssignedIdentities}subscriber-${resourceToken}'
    location: location
  }
}

// publisher
module publisher 'app/publisher.bicep' = {
  name: 'publisher'
  scope: resourceGroup
  params: {
    name: 'publisher'
    location: location
    tags: tags
    exists: publisherAppExists
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    identityName: publisherIdentity.outputs.identityName
    serviceBinds: [ redis.outputs.serviceBind ]
  }
}

// subscriber
module subscriber 'app/subscriber.bicep' = {
  name: 'subscriber'
  scope: resourceGroup
  params: {
    name: 'subscriber'
    location: location
    tags: tags
    exists: subscriberAppExists
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    identityName: subscriberIdentity.outputs.identityName
    serviceBinds: [ redis.outputs.serviceBind ]
  }
}

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerApps.outputs.registryLoginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerApps.outputs.registryName
output ACA_ENVIRONMENT_NAME string = containerApps.outputs.environmentName
