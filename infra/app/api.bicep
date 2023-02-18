param name string
param location string = resourceGroup().location
param tags object = {}

param allowedOrigins array = []
param appCommandLine string = ''
param appServicePlanId string
param appSettings object = {}
param serviceName string = 'api'
param redisCacheId string

module api '../core/host/appservice.bicep' = {
  name: '${name}-app-module'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    allowedOrigins: allowedOrigins
    appCommandLine: appCommandLine
    appServicePlanId: appServicePlanId
    appSettings: union(appSettings, { REDIS_PASSWORD: listKeys(redisCacheId, '2020-06-01').primaryKey })
    runtimeName: 'dotnetcore'
    runtimeVersion: '6.0'
    scmDoBuildDuringDeployment: false
  }
}

output SERVICE_API_NAME string = api.outputs.name
output SERVICE_API_URI string = api.outputs.uri
