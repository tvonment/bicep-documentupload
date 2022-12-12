param location string = resourceGroup().location
param prefix string = 'docup'
param storageAccountName string = '${prefix}${uniqueString(resourceGroup().id)}'
param logworkspaceName string = '${prefix}-loganalytics-${uniqueString(resourceGroup().id)}'
param insightsName string = '${prefix}-appinsights-${uniqueString(resourceGroup().id)}'

param hostingPlanName string = '${prefix}-appservices-plan'
param angularAppName string = '${prefix}-angular-${uniqueString(resourceGroup().id)}'
param jsfunctionsAppName string = '${prefix}-jsfunctions-${uniqueString(resourceGroup().id)}'
param psfunctionsAppName string = '${prefix}-psfunctions-${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  location: location
  name: logworkspaceName
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30

  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  kind: 'web'
  location: location
  name: insightsName
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  location: location
  name: hostingPlanName
  kind: 'linux'
  sku: {
    name: 'S1'
    tier: 'Standard'
  }
  properties: {
    reserved: true
  }
}

resource angularApp 'Microsoft.Web/sites@2022-03-01' = {
  location: location
  name: angularAppName
  kind: 'app,linux'
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      linuxFxVersion: 'NODE|14-lts'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
      ]
      alwaysOn: true
    }
  }
}

resource angularConifg 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'web'
  parent: angularApp
  properties: {
    appCommandLine: 'pm2 serve /home/site/wwwroot --no-daemon --spa'
  }
}

resource jsfunctionsApp 'Microsoft.Web/sites@2022-03-01' = {
  location: location
  name: jsfunctionsAppName
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      linuxFxVersion: 'Node|14'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
      ]
      alwaysOn: true
    }
  }
}

resource psfunctionsApp 'Microsoft.Web/sites@2022-03-01' = {
  location: location
  name: psfunctionsAppName
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      linuxFxVersion: 'PowerShell|7.2'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
      ]
      alwaysOn: true
    }
  }
}
