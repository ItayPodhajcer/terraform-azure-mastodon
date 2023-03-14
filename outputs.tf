output "fqdn" {
  value = azurerm_container_group.this.fqdn
}

output "mastodon_user" {
  value = local.mastodon_user
}

output "mastodon_password" {
  value     = random_password.mastodon.result
  sensitive = true
}
