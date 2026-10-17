
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Existing monitoring network
resource "docker_network" "monitoring" {
  name = "monitor_monitoring"

  lifecycle {
    ignore_changes  = all
    prevent_destroy = true
  }
}

# Existing Prometheus volume
resource "docker_volume" "prometheus_data" {
  name = "monitor_prometheus_data"

  lifecycle {
    ignore_changes  = all
    prevent_destroy = true
  }
}

# Existing Grafana volume
resource "docker_volume" "grafana_data" {
  name = "monitor_grafana_data"

  lifecycle {
    ignore_changes  = all
    prevent_destroy = true
  }
}

# Existing Prometheus container
resource "docker_container" "prometheus" {
  name  = "monitoring-prometheus"
  image = "prom/prometheus:latest"

  restart = "unless-stopped"

  ports {
    internal = 9090
    external = 9090
  }

  networks_advanced {
    name = docker_network.monitoring.name
  }

  mounts {
    type   = "volume"
    source = docker_volume.prometheus_data.name
    target = "/prometheus"
  }

  mounts {
    type      = "bind"
    source    = "/mnt/e/GitLab Projects/tools/monitor/prometheus/prometheus.yml"
    target    = "/etc/prometheus/prometheus.yml"
    read_only = true
  }

  lifecycle {
    ignore_changes  = all
    prevent_destroy = true
  }
}

# Existing Grafana container
resource "docker_container" "grafana" {
  name  = "monitoring-grafana"
  image = "grafana/grafana:latest"

  restart = "unless-stopped"

  env = [
    "GF_SECURITY_ADMIN_USER=admin",
    "GF_SECURITY_ADMIN_PASSWORD=admin123"
  ]

  ports {
    internal = 3000
    external = 3000
  }

  networks_advanced {
    name = docker_network.monitoring.name
  }

  mounts {
    type   = "volume"
    source = docker_volume.grafana_data.name
    target = "/var/lib/grafana"
  }

  lifecycle {
    ignore_changes  = all
    prevent_destroy = true
  }
}

# Node Exporter container
resource "docker_container" "node_exporter" {
  name  = "monitoring-node-exporter"
  image = "prom/node-exporter:latest"

  restart = "unless-stopped"

  ports {
    internal = 9100
    external = 9100
  }

  networks_advanced {
    name = docker_network.monitoring.name
  }

  lifecycle {
    ignore_changes  = all
    prevent_destroy = true
  }
}

