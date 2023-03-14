param name string
param location string = resourceGroup().location
param tags object = {}
param addressPrefix string
param subnetName string
param subnetAddressPrefix string
param postgresSubnetName string
param postgresSubnetAddressPrefix string

resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
      {
        name: postgresSubnetName
        properties: {
          addressPrefix: postgresSubnetAddressPrefix
          delegations: [
            {
              name: 'Microsoft.DBforPostgreSQL/flexibleServers'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
        }
      }
    ]
  }
}

output subnetId string = vnet.properties.subnets[0].id
output postgresSubnetId string = vnet.properties.subnets[1].id
output vnetId string = vnet.id
