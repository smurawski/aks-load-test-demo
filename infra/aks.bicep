param location string = 'eastus'
param aksName string = 'aks-load-testing-demo'



resource aksmalt 'Microsoft.LoadTestService/loadTests@2022-12-01' = {
  name: 'aks-malt'
  location: location
  identity: {
    type: 'None'
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  sku: {
    name: 'Standard'
  }
  name: 'buildailoadtest'
  location: location

  properties: {
    adminUserEnabled: true
    dataEndpointEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
    anonymousPullEnabled: false
  }
}

resource aksdemo 'Microsoft.ContainerService/managedClusters@2023-05-02-preview' = {
  location: location
  name: aksName
  properties: {
    dnsPrefix: 'buildailoadtest'
    agentPoolProfiles: [
      {
        name: 'nodepool1'
        count: 2
        vmSize: 'Standard_DS2_v2'
        osDiskSizeGB: 128
        osDiskType: 'Managed'
        kubeletDiskType: 'OS'
        maxPods: 110
        type: 'VirtualMachineScaleSets'
        maxCount: 10
        minCount: 1
        mode: 'System'
        enableAutoScaling: true
      }
    ]
  }
  identity: {
    type: 'SystemAssigned'
  }
}

var acrPullRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource aksAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: acr // Use when specifying a scope that is different than the deployment scope
  name: guid(aksName, resourceGroup().id, 'Acr', acrPullRole)
  properties: {
    roleDefinitionId: acrPullRole
    principalType: 'ServicePrincipal'
    principalId: aksdemo.properties.identityProfile.kubeletidentity.objectId
  }
}
