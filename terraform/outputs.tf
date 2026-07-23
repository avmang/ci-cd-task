output "artifact_registry_repository" {
  description = "Artifact Registry repository URL"
  value       = "${var.region}-docker.pkg.dev/${var.gd-gcp-gridu-devops-t1-t2}/${google_artifact_registry_repository.repo.repository_id}"
  sensitive   = false
}

output "gd-gcp-gridu-devops-t1-t2" {
  description = "GCP Project ID"
  value       = var.gd-gcp-gridu-devops-t1-t2
  sensitive   = false
}

output "region" {
  description = "GCP Region"
  value       = var.region
  sensitive   = false
}

output "gke_cluster_name" {
  description = "GKE Cluster Name"
  value       = google_container_cluster.primary.name
  sensitive   = false
}

output "gke_cluster_endpoint" {
  description = "GKE Cluster Endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "GKE Cluster CA Certificate"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}
