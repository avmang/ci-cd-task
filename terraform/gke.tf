# GKE Cluster Configuration

resource "google_container_cluster" "primary" {
  name     = "mavoyan-flask-app-cluster"
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Network configuration
  network    = "default"
  subnetwork = "default"

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Enable Autopilot for simplified management (optional)
  # For standard cluster, comment this out
  # enable_autopilot = true

  # Security settings
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # Networking mode
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = ""
    services_ipv4_cidr_block = ""
  }

  # Addons
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  # Cluster logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Resource labels
  resource_labels = {
    environment = var.environment
    project     = "mavoyan-flask-app"
    managed_by  = "terraform"
  }
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "mavoyan-flask-app-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 2

  # Auto-scaling configuration
  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  # Node configuration
  node_config {
    preemptible  = false
    machine_type = "e2-medium"

    # OAuth scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Security
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Resource labels
    labels = {
      environment = var.environment
      project     = "mavoyan-flask-app"
    }

    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Disk configuration
    disk_size_gb = 50
    disk_type    = "pd-standard"

    # Image type
    image_type = "COS_CONTAINERD"
  }

  # Node management
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

# Service Account for GKE nodes
resource "google_service_account" "gke_sa" {
  account_id   = "mavoyan-gke-nodes"
  display_name = "Mavoyan GKE Node Service Account"
  description  = "Service account for GKE cluster nodes"
}

# IAM binding for GKE service account
resource "google_project_iam_member" "gke_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/artifactregistry.reader",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

# Kubernetes Service Account for application
resource "google_service_account" "app_sa" {
  account_id   = "mavoyan-flask-app-k8s"
  display_name = "Mavoyan Flask App Kubernetes Service Account"
  description  = "Service account for Flask application in GKE"
}

# IAM binding for application service account
resource "google_service_account_iam_member" "app_workload_identity" {
  service_account_id = google_service_account.app_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/mavoyan-flask-app]"
}
