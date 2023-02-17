param name string
param location string = resourceGroup().location
param tags object = {}

param databaseName string
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
    databaseNames: [ databaseName ]
    sku: {
      name: 'Standard_B1ms'
      tier: 'Burstable'
    }
    storage: {
      storageSizeGB: 32
      autoGrow: 'Enabled'
    }
    version: '14'
  }
}

output postgresHost string = postgreSql.outputs.POSTGRES_DOMAIN_NAME
