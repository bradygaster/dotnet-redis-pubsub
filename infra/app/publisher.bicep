param name string
param location string = resourceGroup().location
param tags object = {}

param identityName string
param containerAppsEnvironmentName string
param containerRegistryName string
param exists bool
param serviceName string = 'publisher'

resource publisherIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
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
  }
}

output SERVICE_PUBLISHER_IDENTITY_PRINCIPAL_ID string = publisherIdentity.properties.principalId
output SERVICE_PUBLISHER_NAME string = app.outputs.name
output SERVICE_PUBLISHER_URI string = app.outputs.uri
output SERVICE_PUBLISHER_IMAGE_NAME string = app.outputs.imageName
