targetScope = 'subscription'

param resourcesSuffix string = '10'
param environmentName string

param resourceGroupName string = 'traditional-${resourcesSuffix}'
param location string = 'eastus2'

param apiServiceName string = 'ahmels-api-service-azd-${resourcesSuffix}'
param appServicePlanName string = 'ahmels-asp-azd-${resourcesSuffix}'
param postgreSqlAdminUsername string = 'apiuser'
param postgreSqlName string = 'ahmels-postgres-azd-${resourcesSuffix}'
param redisCacheName string = 'ahmels-redis-azd-${resourcesSuffix}'
param webServiceName string = 'ahmels-web-app-name-azd-${resourcesSuffix}'


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
  params: {
    name: apiServiceName
    location: location
    tags: tags
    appServicePlanId: appServicePlan.outputs.id
    allowedOrigins: [ web.outputs.SERVICE_WEB_URI ]
    redisCacheName: redisCacheName
    appSettings: {
      POSTGRES_HOST: postgreSql.outputs.postgresHost
      POSTGRES_PASSWORD: postgreSqlAdminPassword
      POSTGRES_USERNAME: postgreSqlAdminUsername
      POSTGRES_DATABASE: 'postgres'
    }
  }
}

// App outputs
output REACT_APP_API_BASE_URL string = api.outputs.SERVICE_API_URI
output REACT_APP_WEB_BASE_URL string = web.outputs.SERVICE_WEB_URI
