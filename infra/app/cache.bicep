param name string
param location string = resourceGroup().location
param tags object = {}

module cache '../core/cache/redis.bicep' = {
  name: name
  params: {
    name: name
    location: location
    tags: tags
  }
}

output redisName string = cache.outputs.redisName
output redisHost string = cache.outputs.redisHost
output redisPort string = string(cache.outputs.redisPort)
