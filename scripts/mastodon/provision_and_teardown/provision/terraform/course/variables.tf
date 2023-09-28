# variable "db_server_name" {
#   type = string
# }

variable "region" {
  type = string
  default = "eastus"
}

variable "resource_group" {
  type = string
}

# variable "db_admin_username" {
#   type = string
# }

# variable "db_admin_password" {
#   type = string
# }

variable "db_sku" {
  type = string
  default = "B_Standard_B2s"
}

variable "db_version" {
  type = string
  default = "15"
}

variable "db_zone" {
  type = string
  default = "1"
}

variable "db_storage_mb" {
  type = number
  default = 32768
}

variable "db_server_count" {
  type = number
  default = 1
}