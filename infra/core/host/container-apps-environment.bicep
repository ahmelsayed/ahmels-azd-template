param name string
param location string = resourceGroup().location
param tags object = {}
param subnetResourceId string

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-10-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    vnetConfiguration: {
      infrastructureSubnetId: subnetResourceId
    }
  }
}

output name string = containerAppsEnvironment.name
output id string = containerAppsEnvironment.id
output defaultDomain string = containerAppsEnvironment.properties.defaultDomain
