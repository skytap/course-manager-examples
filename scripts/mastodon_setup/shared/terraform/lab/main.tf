terraform {
  required_providers {
    postgresql = {
      source = "cyrilgdn/postgresql"
      version = "1.21.0"
    }
    sendgrid = {
      source = "Trois-Six/sendgrid"
      version = "0.2.1"
    }
  }

  backend "azurerm" {}
}

data "terraform_remote_state" "shared" {
  backend = "azurerm"
  config = {
    storage_account_name = var.storage_account
    container_name = var.container
    key = "shared.tfstate"
    resource_group_name = var.resource_group
    use_azuread_auth = true
  }
}

provider "postgresql" {
  host = data.terraform_remote_state.shared.outputs.db_fqdn
  port = 5432
  database = "postgres"
  username = data.terraform_remote_state.shared.outputs.db_admin_user
  password = data.terraform_remote_state.shared.outputs.db_admin_password
  sslmode = "require"
  superuser = false
}

provider "sendgrid" {
  api_key = var.sendgrid_key
}

resource "random_string" "db_user" {
  length = 16
  special = false
}

resource "random_string" "db_name" {
  length = 16
  special = false
}

resource "random_password" "db_password" {
  length = 16
}

resource "random_password" "mastodon_password" {
  length = 16
}

resource "sendgrid_api_key" "api" {
  name = var.lab_uuid
  scopes = [ "mail.send" ]
}

resource "postgresql_database" "db" {
  name = random_string.db_name.result
}

resource "postgresql_role" "user" {
  name = random_string.db_user.result
  login = true
  password = random_password.db_password.result
}

resource "postgresql_grant" "grant" {
  role = postgresql_role.user.name
  database = postgresql_database.db.name
  object_type = "database"
  privileges = [
    "CONNECT", "CREATE", "TEMPORARY"
  ]
}

resource "postgresql_grant" "schema_grant" {
  role = postgresql_role.user.name
  database = postgresql_database.db.name
  object_type = "schema"
  schema = "public"
  privileges = [
    "CREATE", "USAGE"
  ]
}

