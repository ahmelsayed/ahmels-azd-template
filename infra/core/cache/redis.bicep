param name string
param location string = resourceGroup().location
param tags object = {}
param subnetId string

resource redisServer 'Microsoft.Cache/redis@2022-06-01' = {
  location: location
  tags: tags
  name: name
  properties: {
    sku: {
      name: 'Premium'
      family: 'P'
      capacity: 1
    }
    redisConfiguration: {}
    redisVersion: '6'
    // publicNetworkAccess: 'Disabled'
    subnetId: subnetId
  }
}

output redisHost string = redisServer.properties.hostName
output redisPort int = redisServer.properties.sslPort
output redisName string = redisServer.name
