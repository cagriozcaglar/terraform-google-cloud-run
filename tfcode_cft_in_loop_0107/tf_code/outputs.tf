output "latest_ready_revision" {
  description = "The name of the last revision that was successfully deployed."
  value       = google_cloud_run_v2_service.default.latest_ready_revision
}

output "service_account_email" {
  description = "The email address of the service account used by this Cloud Run service."
  value       = local.service_account_email
}

output "service_id" {
  description = "The fully qualified identifier of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.id
}

output "service_name" {
  description = "The name of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.name
}

output "service_url" {
  description = "The primary public or internal URL of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.uri
}
