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

output REDIS_HOST string = cache.outputs.REDIS_HOST
