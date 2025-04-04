resource "azurerm_service_plan" "function_plan" {
  name                = "asp-${lower(var.project)}-${lower(var.envoirment)}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "B1" 
}

resource "azurerm_storage_account" "function_storage" {
  name                     = "stfunc${lower(var.project)}${lower(var.envoirment)}"  
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  
}

resource "azurerm_redis_cache" "student_redis" { 
  name                = "redis-${lower(var.project)}-${lower(var.envoirment)}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "eastus"
  capacity            = 0
  family              = "C"
  sku_name            = "Basic"
  minimum_tls_version = "1.2"
  redis_configuration {
    maxmemory_policy = "allkeys-lru"
  }
  tags = merge(var.tags, { Environment = "dev" })
}

resource "azurerm_linux_function_app" "message_processor" {
  name                = "func-${lower(var.project)}-${lower(var.envoirment)}"  
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  tags                = var.tags

  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key
  service_plan_id            = azurerm_service_plan.function_plan.id

  
  site_config {
    application_stack {
      python_version = "3.9"  
    }
  }


 app_settings = {
    "AzureWebJobsStorage"        = azurerm_storage_account.function_storage.primary_connection_string
    "FUNCTIONS_WORKER_RUNTIME"  = "python"
    "REDIS_HOST"                = azurerm_redis_cache.student_redis.hostname  
    "REDIS_PORT"                = "6380"
    "REDIS_PASSWORD"            = azurerm_redis_cache.student_redis.primary_access_key  
    "REDIS_SSL"                 = "true"
  }
}