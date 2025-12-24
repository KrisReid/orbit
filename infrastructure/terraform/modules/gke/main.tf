# =============================================================================
# GKE Cluster Module
# =============================================================================
# Creates a production-ready GKE cluster with configurable node pools.
# =============================================================================

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------
data "google_container_engine_versions" "main" {
  project        = var.project_id
  location       = var.region
  version_prefix = var.kubernetes_version_prefix
}

# -----------------------------------------------------------------------------
# GKE Cluster
# -----------------------------------------------------------------------------
resource "google_container_cluster" "main" {
  name     = var.name
  project  = var.project_id
  location = var.regional ? var.region : "${var.region}-a"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Kubernetes version
  min_master_version = data.google_container_engine_versions.main.latest_master_version

  # Network configuration
  network    = var.network
  subnetwork = var.subnetwork

  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # Private cluster configuration
  dynamic "private_cluster_config" {
    for_each = var.enable_private_nodes ? [1] : []
    content {
      enable_private_nodes    = true
      enable_private_endpoint = var.enable_private_endpoint
      master_ipv4_cidr_block  = var.master_ipv4_cidr_block
    }
  }

  # Master authorized networks
  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  # Workload identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Addons
  addons_config {
    http_load_balancing {
      disabled = !var.enable_http_load_balancing
    }
    horizontal_pod_autoscaling {
      disabled = !var.enable_horizontal_pod_autoscaling
    }
    network_policy_config {
      disabled = !var.enable_network_policy
    }
    gce_persistent_disk_csi_driver_config {
      enabled = var.enable_gce_pd_csi_driver
    }
  }

  # Network policy
  dynamic "network_policy" {
    for_each = var.enable_network_policy ? [1] : []
    content {
      enabled  = true
      provider = "CALICO"
    }
  }

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = var.maintenance_start_time
    }
  }

  # Logging and monitoring
  logging_config {
    enable_components = var.logging_enabled_components
  }

  monitoring_config {
    enable_components = var.monitoring_enabled_components
    managed_prometheus {
      enabled = var.enable_managed_prometheus
    }
  }

  # Security
  enable_shielded_nodes = var.enable_shielded_nodes

  # Release channel
  release_channel {
    channel = var.release_channel
  }

  # Resource labels
  resource_labels = var.labels

  # Deletion protection
  deletion_protection = var.deletion_protection

  lifecycle {
    ignore_changes = [
      # Ignore changes to node_config since we manage node pools separately
      node_config,
    ]
  }
}

# -----------------------------------------------------------------------------
# Node Pools
# -----------------------------------------------------------------------------
resource "google_container_node_pool" "main" {
  for_each = var.node_pools

  name     = each.key
  project  = var.project_id
  location = var.regional ? var.region : "${var.region}-a"
  cluster  = google_container_cluster.main.name

  # Node count configuration
  initial_node_count = each.value.initial_node_count

  dynamic "autoscaling" {
    for_each = each.value.enable_autoscaling ? [1] : []
    content {
      min_node_count       = each.value.min_node_count
      max_node_count       = each.value.max_node_count
      location_policy      = each.value.location_policy
    }
  }

  management {
    auto_repair  = each.value.auto_repair
    auto_upgrade = each.value.auto_upgrade
  }

  upgrade_settings {
    max_surge       = each.value.max_surge
    max_unavailable = each.value.max_unavailable
  }

  node_config {
    machine_type = each.value.machine_type
    disk_size_gb = each.value.disk_size_gb
    disk_type    = each.value.disk_type

    # Use Container-Optimized OS
    image_type = each.value.image_type

    # Service account
    service_account = var.node_service_account
    oauth_scopes    = each.value.oauth_scopes

    # Labels and tags
    labels = merge(var.labels, each.value.labels)
    tags   = each.value.tags

    # Workload identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Shielded instance config
    shielded_instance_config {
      enable_secure_boot          = each.value.enable_secure_boot
      enable_integrity_monitoring = each.value.enable_integrity_monitoring
    }

    # Preemptible/Spot
    preemptible = each.value.preemptible
    spot        = each.value.spot

    # Taints
    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }

  lifecycle {
    ignore_changes = [
      initial_node_count,
    ]
  }
}
