terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "mavoyan-tf-bucket"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.gd-gcp-gridu-devops-t1-t2
  region  = var.region
}

resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "mavoyan-flask-app-repo"
  format        = "DOCKER"
}

