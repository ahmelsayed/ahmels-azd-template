param name string
param location string = resourceGroup().location
param tags object = {}

resource redisServer 'Microsoft.Cache/redis@2022-06-01' = {
  location: location
  tags: tags
  name: name
  properties: {
    sku: {
      name: 'Standard'
      family: 'C'
      capacity: 1
    }
    redisConfiguration: {}
    redisVersion: '6'
  }
}


output redisHost string = redisServer.properties.hostName
output redisId string = redisServer.id
