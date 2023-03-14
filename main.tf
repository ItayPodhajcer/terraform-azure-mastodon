provider "azurerm" {
  features {}
}

locals {
  name           = "${var.deployment_name}-${var.location}"
  database_user  = "dbuser"
  mastodon_user  = "user"
  mastodon_email = "user@email.com"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name}"
  location = var.location
}

resource "random_password" "database" {
  special = false
  length  = 16
}

resource "random_password" "elastic" {
  special = false
  length  = 16
}

resource "random_password" "mastodon" {
  special = false
  length  = 16
}

resource "azurerm_container_group" "this" {
  name                = "aci-${local.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  ip_address_type     = "Public"
  dns_name_label      = local.name
  os_type             = "Linux"

  exposed_port {
    port     = "3000"
    protocol = "TCP"
  }

  exposed_port {
    port     = "4000"
    protocol = "TCP"
  }

  container {
    name   = "postgresql"
    image  = "docker.io/bitnami/postgresql:15"
    cpu    = "0.5"
    memory = "1"

    environment_variables = {
      "POSTGRESQL_DATABASE" = "bitnami_mastodon"
      "POSTGRESQL_USERNAME" = local.database_user
    }

    secure_environment_variables = {
      "POSTGRESQL_PASSWORD" = random_password.database.result
    }

    ports {
      port     = "5432"
      protocol = "TCP"
    }

    volume {
      name       = "postgresql-data"
      mount_path = "/bitnami/postgresql"
      empty_dir  = true
    }
  }

  container {
    name   = "redis"
    image  = "docker.io/bitnami/redis:7.0"
    cpu    = "0.5"
    memory = "1"

    environment_variables = {
      "ALLOW_EMPTY_PASSWORD" = "yes"
    }

    ports {
      port     = "6379"
      protocol = "TCP"
    }

    volume {
      name       = "redis-data"
      mount_path = "/bitnami/redis"
      empty_dir  = true
    }
  }

  container {
    name   = "elasticsearch"
    image  = "docker.io/bitnami/elasticsearch:8"
    cpu    = "1"
    memory = "2"

    environment_variables = {
      "ELASTICSEARCH_ENABLE_SECURITY"    = "true"
      "ELASTICSEARCH_SKIP_TRANSPORT_TLS" = "true"
    }

    secure_environment_variables = {
      "ELASTICSEARCH_PASSWORD" = random_password.elastic.result
    }

    ports {
      port     = "9200"
      protocol = "TCP"
    }

    volume {
      name       = "elasticsearch-data"
      mount_path = "/bitnami/elasticsearch/data"
      empty_dir  = true
    }
  }

  container {
    name   = "mastodon"
    image  = "docker.io/bitnami/mastodon:4"
    cpu    = "0.5"
    memory = "1"

    ports {
      port     = "3000"
      protocol = "TCP"
    }

    environment_variables = {
      "BITNAMI_DEBUG"               = "true"
      "ALLOW_EMPTY_PASSWORD"        = "yes"
      "MASTODON_MODE"               = "web"
      "MASTODON_REDIS_HOST"         = "localhost"
      "MASTODON_DATABASE_HOST"      = "localhost"
      "MASTODON_DATABASE_USERNAME"  = local.database_user
      "MASTODON_ELASTICSEARCH_HOST" = "localhost"
      "MASTODON_ADMIN_USERNAME"     = local.mastodon_user
      "MASTODON_ADMIN_EMAIL"        = local.mastodon_email
    }

    secure_environment_variables = {
      "MASTODON_DATABASE_PASSWORD"      = random_password.database.result
      "MASTODON_ELASTICSEARCH_PASSWORD" = random_password.elastic.result
      "MASTODON_ADMIN_PASSWORD"         = random_password.mastodon.result
    }

    volume {
      name       = "mastodon-data"
      mount_path = "/bitnami/mastodon"
      empty_dir  = true
    }
  }

  container {
    name   = "mastodon-streaming"
    image  = "docker.io/bitnami/mastodon:4"
    cpu    = "0.5"
    memory = "1"

    ports {
      port     = "4000"
      protocol = "TCP"
    }

    environment_variables = {
      "ALLOW_EMPTY_PASSWORD"        = "yes"
      "MASTODON_MODE"               = "streaming"
      "MASTODON_REDIS_HOST"         = "localhost"
      "MASTODON_DATABASE_HOST"      = "localhost"
      "MASTODON_DATABASE_USERNAME"  = local.database_user
      "MASTODON_ELASTICSEARCH_HOST" = "localhost"
      "MASTODON_WEB_HOST"           = "localhost"
    }

    secure_environment_variables = {
      "MASTODON_DATABASE_PASSWORD"      = random_password.database.result
      "MASTODON_ELASTICSEARCH_PASSWORD" = random_password.elastic.result
    }
  }

  container {
    name   = "mastodon-sidekiq"
    image  = "docker.io/bitnami/mastodon:4"
    cpu    = "0.5"
    memory = "1"

    environment_variables = {
      "ALLOW_EMPTY_PASSWORD"        = "yes"
      "MASTODON_MODE"               = "sidekiq"
      "MASTODON_REDIS_HOST"         = "localhost"
      "MASTODON_DATABASE_HOST"      = "localhost"
      "MASTODON_DATABASE_USERNAME"  = local.database_user
      "MASTODON_ELASTICSEARCH_HOST" = "localhost"
      "MASTODON_WEB_HOST"           = "localhost"
    }

    secure_environment_variables = {
      "MASTODON_DATABASE_PASSWORD"      = random_password.database.result
      "MASTODON_ELASTICSEARCH_PASSWORD" = random_password.elastic.result
    }

    volume {
      name       = "mastodon-data"
      mount_path = "/bitnami/mastodon"
      empty_dir  = true
    }
  }
}
