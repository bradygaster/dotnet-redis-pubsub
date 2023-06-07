param identityName string
param location string = resourceGroup().location

resource publisherIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

output identityName string = publisherIdentity.name
