terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.54.0"
    }
  }
}

provider "azurerm" {
  features {}
 
 subscription_id = "f651a542-4390-4c89-a568-5a359fa1d9e8"
 
}