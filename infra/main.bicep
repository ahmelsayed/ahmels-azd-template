targetScope = 'subscription'

param environmentName string
param location string
param resourceGroupName string = ''

param resourcesSuffix string = '005'
param postgreSqlAdminUsername string = 'apiuser'
param postgreSqlName string = 'postgres-azd-${resourcesSuffix}'
param redisCacheName string = 'redis-azd-${resourcesSuffix}'

param acaLocation string = 'northcentralusstage' // use North Central US (Stage) for ACA resources
param acaEnvironmentName string = 'aca-env'
param webServiceName string = 'web-service'
param apiServiceName string = 'api-service'
param webImageName string = 'docker.io/ahmelsayed/springboard-web:latest'
param apiImageName string = 'docker.io/ahmelsayed/springboard-api:p'

@secure()
param postgreSqlAdminPassword string

var tags = { 'azd-env-name': environmentName }

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${environmentName}-rg'
  location: location
  tags: tags
}

module cache './app/cache.bicep' = {
  name: 'cache'
  scope: rg
  params: {
    name: redisCacheName
    location:location
    tags: tags
  }
}

module postgreSql './app/db.bicep' = {
  name: 'sql'
  scope: rg
  params: {
    name: postgreSqlName
    location: location
    tags: tags
    postgresAdminPassword: postgreSqlAdminPassword
    postgresAdminUser: postgreSqlAdminUsername
  }
}

module acaEnvironment './core/host/container-apps-environment.bicep' = {
  name: 'container-apps-environment'
  scope: rg
  params: {
    name: acaEnvironmentName
    location: acaLocation
    tags: tags
  }
}

module api './core/host/container-app.bicep' = {
  name: 'api'
  scope: rg
  params: {
    name: apiServiceName
    location: acaLocation
    tags: tags
    managedEnvironmentId: acaEnvironment.outputs.id
    imageName: apiImageName
    targetPort: 80
    allowedOrigins: [ '${webServiceName}.${acaEnvironment.outputs.defaultDomain}' ]
    env: [
      {name: 'POSTGRES_HOST', value: postgreSql.outputs.postgresHost}
      {name: 'POSTGRES_PASSWORD', value: postgreSqlAdminPassword}
      {name: 'POSTGRES_USERNAME', value: postgreSqlAdminUsername}
      {name: 'POSTGRES_DATABASE', value: 'postgres'}
      {name: 'REDIS_HOST', value: cache.outputs.redisHost}
      {name: 'REDIS_PORT', value: cache.outputs.redisPort}
      {name: 'REDIS_USE_SSL', value: 'true'}
    ]
    redisCacheName: cache.outputs.redisName
  }
}

// the application frontend
module web './core/host/container-app-1.bicep' = {
  name: 'web'
  scope: rg
  params: {
    name: webServiceName
    location: acaLocation
    tags: tags
    managedEnvironmentId: acaEnvironment.outputs.id
    imageName: webImageName
    targetPort: 80
    env: [
      {
        name: 'REACT_APP_API_BASE_URL'
        value: 'https://${apiServiceName}.${acaEnvironment.outputs.defaultDomain}'
      }
    ]
  }
}

// App outputs
output REACT_APP_API_BASE_URL string = api.outputs.uri
output REACT_APP_WEB_BASE_URL string = web.outputs.uri
