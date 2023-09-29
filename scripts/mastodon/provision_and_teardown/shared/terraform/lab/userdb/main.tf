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