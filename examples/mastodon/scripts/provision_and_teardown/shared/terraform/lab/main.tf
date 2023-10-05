# Copyright 2023 Skytap Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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

resource "postgresql_role" "user" {
  name = var.lab_id
  login = true
  create_database = true
  password = random_password.db_password.result
}

provider "sendgrid" {
  api_key = var.sendgrid_key
}

resource "random_password" "db_password" {
  length = 16
  special = false
}

resource "random_password" "mastodon_password" {
  length = 16
  special = false
}

resource "sendgrid_api_key" "api" {
  name = var.lab_id
  scopes = [ "mail.send" ]
}

module "user_db" {
  source = "./userdb"
  db_fqdn = data.terraform_remote_state.shared.outputs.db_fqdn
  db_name = var.lab_id
  pg_user = postgresql_role.user.name
  pg_password = postgresql_role.user.password
}

resource "postgresql_grant" "schema_grant" {
  role = postgresql_role.user.name
  database = module.user_db.db_name
  object_type = "schema"
  schema = "public"
  privileges = [
    "CREATE", "USAGE"
  ]
}
