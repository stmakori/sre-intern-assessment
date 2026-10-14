terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Authentication comes from `az login`; the subscription ID comes from the
# ARM_SUBSCRIPTION_ID environment variable. No credentials in code.
provider "azurerm" {
  features {}
}
