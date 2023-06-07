param name string
param location string = resourceGroup().location
param tags object = {}

param identityName string
param containerAppsEnvironmentName string
param containerRegistryName string
param exists bool
param serviceName string = 'subscriber'

@description('An array of service binds')
param serviceBinds array

resource subscriberIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

module app '../core/host/container-app-upsert.bicep' = {
  name: '${serviceName}-container-app'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    identityType: 'UserAssigned'
    identityName: identityName
    exists: exists
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    env: [
      {
        name: 'ASPNETCORE_ENVIRONMENT'
        value: 'Development'
      }
    ]
    targetPort: 80
    serviceBinds: serviceBinds
  }
}

output SERVICE_SUBSCRIBER_IDENTITY_PRINCIPAL_ID string = subscriberIdentity.properties.principalId
output SERVICE_SUBSCRIBER_NAME string = app.outputs.name
output SERVICE_SUBSCRIBER_URI string = app.outputs.uri
output SERVICE_SUBSCRIBER_IMAGE_NAME string = app.outputs.imageName
