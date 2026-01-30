terraform {
  backend "azurerm" {
    resource_group_name  = "tw-tfstate"
    storage_account_name = "tfstateattackpathtw"
    container_name       = "tfstate"
    key                  = "attack-path-hw.tfstate"
  }
}
