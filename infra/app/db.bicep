param name string
param location string = resourceGroup().location
param tags object = {}
param subnetId string
param privateDnsZoneId string

param postgresAdminUser string

@secure()
param postgresAdminPassword string

module postgreSql '../core/database/postgresql/flexibleserver.bicep' = {
  name: 'postgreSql'
  params: {
    name: name
    location: location
    tags: tags
    administratorLoginPassword: postgresAdminPassword
    administratorLogin: postgresAdminUser
    allowAzureIPsFirewall: true
    sku: {
      name: 'Standard_B1ms'
      tier: 'Burstable'
    }
    storage: {
      storageSizeGB: 32
      autoGrow: 'Enabled'
    }
    version: '14'
    subnetId: subnetId
    privateDnsZoneId: privateDnsZoneId
  }
}

output postgresHost string = postgreSql.outputs.POSTGRES_DOMAIN_NAME
