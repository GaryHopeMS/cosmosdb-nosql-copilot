metadata description = 'Create web apps.'

param planName string
param appName string
param serviceTag string
param location string = resourceGroup().location
param tags object = {}

@description('SKU of the App Service Plan.')
param sku string = 'P0v3'

@description('Endpoint for Azure Cosmos DB for NoSQL account.')
param databaseAccountEndpoint string

@description('Endpoint for Azure OpenAI account.')
param openAiAccountEndpoint string

type openAiOptions = {
  completionDeploymentName: string
  embeddingDeploymentName: string
}

@description('Application configuration settings for OpenAI.')
param openAiSettings openAiOptions

type cosmosDbOptions = {
  database: string
  chatContainer: string
  cacheContainer: string
  productContainer: string
  productDataSource: string
}
@description('Application configuration settings for Azure Cosmos DB.')
param cosmosDbSettings cosmosDbOptions

type chatOptions = {
  maxConversationTokens: string
  cacheSimilarityScore: string
  productMaxResults: string
}

@description('Application configuration settings for Chat Service.')
param chatSettings chatOptions

type managedIdentity = {
  resourceId: string
  clientId: string
}

@description('Unique identifier for user-assigned managed identity.')
param userAssignedManagedIdentity managedIdentity

module appServicePlan '../core/host/app-service/plan.bicep' = {
  name: 'app-service-plan'
  params: {
    name: planName
    location: location
    tags: tags
    sku: sku
    kind: 'linux'
  }
}

module appServiceWebApp '../core/host/app-service/site.bicep' = {
  name: 'app-service-web-app'
  params: {
    name: appName
    location: location
    tags: union(tags, {
      'azd-service-name': serviceTag
    })
    parentPlanName: appServicePlan.outputs.name
    runtimeName: 'dotnetcore'
    runtimeVersion: '8.0'
    kind: 'app,linux'
    enableSystemAssignedManagedIdentity: false
    userAssignedManagedIdentityIds: [
      userAssignedManagedIdentity.resourceId
    ]
  }
}

module appServiceWebAppConfig '../core/host/app-service/config.bicep' = {
  name: 'app-service-config'
  params: {
    parentSiteName: appServiceWebApp.outputs.name
    appSettings: {
      OPENAI__ENDPOINT: openAiAccountEndpoint
      OPENAI__COMPLETIONDEPLOYMENTNAME: openAiSettings.completionDeploymentName
      OPENAI__EMBEDDINGDEPLOYMENTNAME: openAiSettings.embeddingDeploymentName
      SEMANTICKERNEL__ENDPOINT: openAiAccountEndpoint
      SEMANTICKERNEL__COMPLETIONDEPLOYMENTNAME: openAiSettings.completionDeploymentName
      SEMANTICKERNEL__EMBEDDINGDEPLOYMENTNAME: openAiSettings.embeddingDeploymentName
      COSMOSDB__ENDPOINT: databaseAccountEndpoint
      COSMOSDB__DATABASE: cosmosDbSettings.database
      COSMOSDB__CHATCONTAINER: cosmosDbSettings.chatContainer
      COSMOSDB__CACHECONTAINER: cosmosDbSettings.cacheContainer
      COSMOSDB__PRODUCTCONTAINER: cosmosDbSettings.productContainer
      COSMOSDB__PRODUCTDATASOURCE: cosmosDbSettings.productDataSource
      CHAT_MAXCONVERSATIONTOKENS: chatSettings.maxConversationTokens
      CHAT_CACHESIMILARITYSCORE: chatSettings.cacheSimilarityScore
      CHAT_PRODUCTMAXRESULTS: chatSettings.productMaxResults
      AZURE_CLIENT_ID: userAssignedManagedIdentity.clientId
    }
  }
}

output name string = appServiceWebApp.outputs.name
output endpoint string = appServiceWebApp.outputs.endpoint
