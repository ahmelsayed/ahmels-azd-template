targetScope = 'subscription'

param environmentName string
param location string

param apiServiceName string
param appServicePlanName string
param resourceGroupName string
param postgreSqlName string
param postgreSqlAdminUsername string
param webServiceName string
param redisCacheName string

@secure()
param postgreSqlAdminPassword string

var tags = { 'azd-env-name': environmentName }

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
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

// The application frontend
module web './app/web.bicep' = {
  name: 'web'
  scope: rg
  params: {
    name: webServiceName
    location: location
    tags: tags
    appServicePlanId: appServicePlan.outputs.id
  }
}

// The application backend
module api './app/api.bicep' = {
  name: 'api'
  scope: rg
  dependsOn: [
    postgreSql
    cache
  ]
  params: {
    name: apiServiceName
    location: location
    tags: tags
    appServicePlanId: appServicePlan.outputs.id
    allowedOrigins: [ web.outputs.SERVICE_WEB_URI ]
    redisCacheId: cache.outputs.redisId
    appSettings: {
      POSTGRES_HOST: postgreSql.outputs.postgresHost
      POSTGRES_PASSWORD: postgreSqlAdminPassword
      POSTGRES_USERNAME: postgreSqlAdminUsername
      POSTGRES_DATABASE: 'postgres'
      REDIS_HOST: cache.outputs.redisHost
    }
  }
}

// The application database
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

// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: appServicePlanName
    location: location
    tags: tags
    sku: {
      name: 'B1'
    }
  }
}

// Data outputs
output POSTGRES_HOST string = postgreSql.outputs.postgresHost

// App outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output REACT_APP_API_BASE_URL string = api.outputs.SERVICE_API_URI
output REACT_APP_WEB_BASE_URL string = web.outputs.SERVICE_WEB_URI
