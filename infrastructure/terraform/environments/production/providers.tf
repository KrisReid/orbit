# =============================================================================
# Orbit Production Environment - Provider Configuration
# =============================================================================
# Configures providers based on the selected cloud_provider.
# =============================================================================

# -----------------------------------------------------------------------------
# Locals for Provider Configuration
# -----------------------------------------------------------------------------
locals {
  # Kubernetes cluster connection details (resolved after cluster creation)
  cluster_endpoint = (
    var.cloud_provider == "aws" 
    ? try(module.kubernetes_aws[0].cluster_endpoint, "") 
    : var.cloud_provider == "gcp" 
    ? "https://${try(module.kubernetes_gcp[0].cluster_endpoint, "")}" 
    : ""
  )

  cluster_ca_certificate = (
    var.cloud_provider == "aws" 
    ? try(module.kubernetes_aws[0].cluster_ca_certificate, "") 
    : var.cloud_provider == "gcp" 
    ? try(module.kubernetes_gcp[0].cluster_ca_certificate, "") 
    : ""
  )
}

# -----------------------------------------------------------------------------
# AWS Provider
# -----------------------------------------------------------------------------
provider "aws" {
  # Use var.region only when deploying to AWS; use a valid default region otherwise
  # (AWS provider must be configured even when using GCP/Azure)
  region = var.cloud_provider == "aws" ? var.region : "us-east-1"

  # Skip AWS credential/API validation when not using AWS
  skip_credentials_validation = var.cloud_provider != "aws"
  skip_metadata_api_check     = var.cloud_provider != "aws"
  skip_requesting_account_id  = var.cloud_provider != "aws"

  default_tags {
    tags = {
      environment = var.environment
      project     = var.project_name
      managedby   = "terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# GCP Provider
# -----------------------------------------------------------------------------
provider "google" {
  project = try(var.gcp_config.project_id, null)
  region  = var.region
}

# -----------------------------------------------------------------------------
# GCP Client Config (for GKE authentication)
# -----------------------------------------------------------------------------
data "google_client_config" "default" {
  count = var.cloud_provider == "gcp" ? 1 : 0
}

# -----------------------------------------------------------------------------
# Kubernetes Provider
# -----------------------------------------------------------------------------
provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate

  # AWS EKS uses exec plugin for authentication
  dynamic "exec" {
    for_each = var.cloud_provider == "aws" ? [1] : []
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", var.region]
    }
  }

  # GCP GKE uses token-based authentication
  token = var.cloud_provider == "gcp" ? try(data.google_client_config.default[0].access_token, null) : null
}

# -----------------------------------------------------------------------------
# Helm Provider
# -----------------------------------------------------------------------------
provider "helm" {
  kubernetes = {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = local.cluster_ca_certificate
    token                  = var.cloud_provider == "gcp" ? try(data.google_client_config.default[0].access_token, null) : null
  }
}

# -----------------------------------------------------------------------------
# Kubectl Provider
# -----------------------------------------------------------------------------
provider "kubectl" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  load_config_file       = false

  dynamic "exec" {
    for_each = var.cloud_provider == "aws" ? [1] : []
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", var.region]
    }
  }

  token = var.cloud_provider == "gcp" ? try(data.google_client_config.default[0].access_token, null) : null
}
