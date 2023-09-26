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
  value = postgresql_database.db.name
}

output "mastodon_password" {
  value = random_password.mastodon_password.result
  sensitive = true
}