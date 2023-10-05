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

variable "region" {
  type = string
  default = "eastus"
}

variable "resource_group" {
  type = string
}

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