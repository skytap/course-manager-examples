variable "storage_account" {
  type = string
}

variable "container" {
  type = string
}

variable "resource_group" {
  type = string
}

variable "lab_id" {
  type = string
}

variable "sendgrid_key" {
  type = string
  sensitive = true
}