# <!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
# This file is automatically managed by terraform-docs.
# Do not edit manually.
# <!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
output "id" {
  description = "The fully qualified identifier of the Cloud Run service."
  value       = google_cloud_run_v2_service.main.id
}

output "name" {
  description = "The name of the Cloud Run service."
  value       = google_cloud_run_v2_service.main.name
}

output "location" {
  description = "The location where the Cloud Run service is deployed."
  value       = google_cloud_run_v2_service.main.location
}

output "uri" {
  description = "The primary public URI of the Cloud Run service."
  value       = google_cloud_run_v2_service.main.uri
}

output "latest_ready_revision" {
  description = "The name of the latest revision of the service that is ready to serve traffic."
  value       = google_cloud_run_v2_service.main.latest_ready_revision
}

output "service_account_email" {
  description = "The email of the service account used by the Cloud Run service."
  value       = local.service_account_email
}
