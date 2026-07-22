output "workload_identity_provider" {
  description = "Workload Identity Provider for GitHub Actions"
  value       = google_iam_workload_identity_pool_provider.github.name
  sensitive   = false
}

output "service_account_email" {
  description = "Service account email for GitHub Actions"
  value       = google_service_account.github_sa.email
  sensitive   = false
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}"
  sensitive   = false
}

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
  sensitive   = false
}

output "region" {
  description = "GCP Region"
  value       = var.region
  sensitive   = false
}
