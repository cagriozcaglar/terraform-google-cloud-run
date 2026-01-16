# This file provisions the necessary prerequisite resources (like service accounts and secrets)
# and then instantiates the Cloud Run module to deploy a comprehensive service.

terraform {
  required_providers {
    google = {
      source  = "hashcorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "google" {
  project = var.project_id
}

# Use a random suffix to avoid naming conflicts
resource "random_id" "suffix" {
  byte_length = 4
}

# Enable required APIs for the example
resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",
    "iam.googleapis.com",
    "secretmanager.googleapis.com",
    "vpcaccess.googleapis.com",
    "compute.googleapis.com"
  ])
  service                    = each.key
  disable_on_destroy         = false
  disable_dependent_services = true
}

# Create a dedicated service account for the Cloud Run service to run as
resource "google_service_account" "run_sa" {
  account_id   = "run-sa-${random_id.suffix.hex}"
  display_name = "Cloud Run Example Service Account"
  depends_on   = [google_project_service.apis]
}

# Create another service account that will be granted permission to invoke the service
resource "google_service_account" "invoker_sa" {
  account_id   = "run-invoker-sa-${random_id.suffix.hex}"
  display_name = "Cloud Run Example Invoker Service Account"
  depends_on   = [google_project_service.apis]
}

# Create a secret to be injected as an environment variable
resource "google_secret_manager_secret" "env_secret" {
  secret_id = "run-env-secret-${random_id.suffix.hex}"
  replication {
    automatic = true
  }
  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "env_secret_version" {
  secret      = google_secret_manager_secret.env_secret.id
  secret_data = "super-secret-api-key"
}

# Create a secret to be mounted as a file volume
resource "google_secret_manager_secret" "volume_secret" {
  secret_id = "run-volume-secret-${random_id.suffix.hex}"
  replication {
    automatic = true
  }
  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "volume_secret_version" {
  secret      = google_secret_manager_secret.volume_secret.id
  secret_data = "This is configuration mounted from a file."
}

# Grant the Cloud Run service account access to the secrets
resource "google_secret_manager_secret_iam_member" "env_secret_accessor" {
  project   = google_secret_manager_secret.env_secret.project
  secret_id = google_secret_manager_secret.env_secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.run_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "volume_secret_accessor" {
  project   = google_secret_manager_secret.volume_secret.project
  secret_id = google_secret_manager_secret.volume_secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.run_sa.email}"
}


# Create a VPC and Serverless VPC Access Connector for the service to use
resource "google_compute_network" "vpc_network" {
  name                    = "run-vpc-${random_id.suffix.hex}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vpc_subnetwork" {
  name          = "run-subnet-${random_id.suffix.hex}"
  ip_cidr_range = "10.10.10.0/28"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_vpc_access_connector" "connector" {
  name          = "run-connector-${random_id.suffix.hex}"
  region        = var.region
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.vpc_network.id
  depends_on    = [google_project_service.apis]
}
