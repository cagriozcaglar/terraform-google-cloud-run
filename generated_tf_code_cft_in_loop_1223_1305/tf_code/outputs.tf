# The outputs.tf file defines the values that the module will return.
output "id" {
  description = "The fully qualified identifier of the Cloud Run service."
  value       = google_cloud_run_v2_service.main.id
}

output "latest_ready_revision" {
  description = "The name of the latest revision of the service that is ready to serve traffic."
  value       = google_cloud_run_v2_service.main.latest_ready_revision
}

output "location" {
  description = "The location of the Cloud Run service."
  value       = google_cloud_run_v2_service.main.location
}

output "name" {
  description = "The name of the Cloud Run service."
  value       = google_cloud_run_v2_service.main.name
}

output "service_account_email" {
  description = "The email of the service account used by the service. This is the email of the created service account if `create_service_account` is true, otherwise it is the value of `service_account_email`."
  value       = local.service_account_email
}

output "uri" {
  description = "The primary public URI of the Cloud Run service."
  value       = google_cloud_run_v2_service.main.uri
}
