terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.14"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstatelab"
    container_name       = "tfstate"
    key                  = "hybrid-lab.tfstate"
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}
