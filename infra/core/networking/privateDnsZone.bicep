param name string
param tags object = {}
param vnetId string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: name
  location: 'global'
  tags: tags

  resource privateDnsZoneLink 'virtualNetworkLinks' = {
    name: uniqueString(vnetId)
    location: 'global'
    tags: tags
    properties: {
      virtualNetwork: {
        id: vnetId
      }
      registrationEnabled: false
    }
  }
}

output privateDnsZoneId string = privateDnsZone.id
