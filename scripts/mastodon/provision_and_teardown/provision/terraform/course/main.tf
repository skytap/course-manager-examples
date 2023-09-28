terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.73.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

resource "random_uuid" "db_server" {}

resource "random_string" "db_admin_user" {
  length = 16
  special = false
}

resource "random_password" "db_admin_password" {
  length = 16
}

resource "azurerm_postgresql_flexible_server" "db" {
  name = random_uuid.db_server.result
  resource_group_name = var.resource_group
  location = var.region
  version = var.db_version
  administrator_login = random_string.db_admin_user.result
  administrator_password = random_password.db_admin_password.result
  storage_mb = var.db_storage_mb
  sku_name = var.db_sku
  zone = var.db_zone
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "fw" {
  name = "global"
  server_id = azurerm_postgresql_flexible_server.db.id
  start_ip_address = "0.0.0.0"
  end_ip_address = "255.255.255.255"
}

resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  name = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.db.id
  value = "plpgsql"
}