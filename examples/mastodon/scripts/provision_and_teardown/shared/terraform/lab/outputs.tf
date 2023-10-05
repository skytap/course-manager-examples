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

output "sg_key" {
  value = sendgrid_api_key.api.api_key
  sensitive = true
}

output "db_fqdn" {
  value = data.terraform_remote_state.shared.outputs.db_fqdn
}

output "db_username" {
  value = postgresql_role.user.name
}

output "db_password" {
  value = postgresql_role.user.password
  sensitive = true
}

output "db_name" {
  value = module.user_db.db_name
}

output "mastodon_admin_password" {
  value = random_password.mastodon_password.result
  sensitive = true
}