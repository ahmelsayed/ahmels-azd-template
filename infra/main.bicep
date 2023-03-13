targetScope = 'subscription'

param environmentName string
param location string
param resourceGroupName string = ''

param resourcesSuffix string = '006'
param postgreSqlAdminUsername string = 'apiuser'
param postgreSqlName string = 'postgres-azd-${resourcesSuffix}'
param redisCacheName string = 'redis-azd-${resourcesSuffix}'

// param acaLocation string = 'northcentralusstage' // use North Central US (Stage) for ACA resources
param acaEnvironmentName string = 'aca-env'
param webServiceName string = 'web-service'
param apiServiceName string = 'api-service'
param webImageName string = 'docker.io/ahmelsayed/springboard-web:latest'
param apiImageName string = 'docker.io/ahmelsayed/springboard-api:p'
param postgresPrivateDnsZoneName string = 'postgres-${resourcesSuffix}.private.postgres.database.azure.com'

@secure()
param postgreSqlAdminPassword string

var tags = { 'azd-env-name': environmentName }

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${environmentName}-rg'
  location: location
  tags: tags
}

module vnet './core/networking/vnet.bicep' = {
  name: 'vnet'
  scope: rg
  params: {
    name: 'vnet'
    location: location
    tags: tags
    addressPrefix: '10.0.0.0/16'
    subnetName: 'infrastructure-subnet'
    subnetAddressPrefix: '10.0.0.0/23'
    postgresSubnetName: 'postgres-subnet'
    postgresSubnetAddressPrefix: '10.0.2.0/24'
  }
}

module postgresPrivateDnsZone './core/networking/privateDnsZone.bicep' = {
  name: 'postgresPrivateDnsZone'
  scope: rg
  dependsOn: [
    vnet
  ]  
  params: {
    name: postgresPrivateDnsZoneName
    tags: tags
    vnetId: vnet.outputs.vnetId
  }
}

module cache './app/cache.bicep' = {
  name: 'cache'
  scope: rg
  params: {
    name: redisCacheName
    location:location
    tags: tags
    subnetId: vnet.outputs.subnetId
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
    subnetId: vnet.outputs.postgresSubnetId
    privateDnsZoneId: postgresPrivateDnsZone.outputs.privateDnsZoneId
  }
}

module acaEnvironment './core/host/container-apps-environment.bicep' = {
  name: 'container-apps-environment'
  scope: rg
  params: {
    name: acaEnvironmentName
    location: location
    tags: tags
    subnetResourceId: vnet.outputs.subnetId
  }
}

module api './core/host/container-app.bicep' = {
  name: 'api'
  scope: rg
  params: {
    name: apiServiceName
    location: location
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
    location: location
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
