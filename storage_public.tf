resource "random_string" "sa_suffix" {
  length  = 8
  upper   = false
  special = false
}

# Storage account name musi być: 3-24 znaki, tylko małe litery i cyfry
locals {
  public_sa_name = substr(lower("${var.public_storage_account_prefix}${random_string.sa_suffix.result}"), 0, 24)
}

resource "azurerm_storage_account" "public" {
  name                     = local.public_sa_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # publiczny dostęp sieciowy
  public_network_access_enabled = true

  # pozwól na publiczny odczyt blobów
  allow_nested_items_to_be_public = true

  min_tls_version = "TLS1_2"
  tags = {
    yor_trace = "e070caf1-0f85-426d-8425-8b7f8a27fdcc"
  }
}

resource "azurerm_storage_container" "public" {
  name                  = var.public_container_name
  storage_account_name  = azurerm_storage_account.public.name
  container_access_type = "blob" # publiczny odczyt blobów; kontener pusty i tak
}
