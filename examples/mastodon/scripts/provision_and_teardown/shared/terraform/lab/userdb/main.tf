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
}

provider "postgresql" {
  host = var.db_fqdn
  port = 5432
  database = "postgres"
  username = var.pg_user
  password = var.pg_password
  sslmode = "require"
  superuser = false
}

resource "postgresql_database" "db" {
  name = var.db_name
}