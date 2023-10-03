variable "db_fqdn" {
  type = string
}

variable "pg_user" {
  type = string
  sensitive = true
}

variable "pg_password" {
  type = string
  sensitive = true
}

variable "db_name" {
  type = string
}