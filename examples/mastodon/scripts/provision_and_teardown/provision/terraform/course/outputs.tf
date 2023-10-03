output "db_fqdn" {
  value = azurerm_postgresql_flexible_server.db.fqdn
  # value = length(azurerm_postgresql_flexible_server.db) > 0 ? azurerm_postgresql_flexible_server.db[0].fqdn : null
}

output "db_admin_user" {
  value = azurerm_postgresql_flexible_server.db.administrator_login
}

output "db_admin_password" {
  value = azurerm_postgresql_flexible_server.db.administrator_password
  sensitive = true
}