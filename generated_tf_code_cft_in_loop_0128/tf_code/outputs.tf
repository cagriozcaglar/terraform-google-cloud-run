# The URL of the deployed service.
output "service_url" {
  description = "The publicly-accessible URL of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.uri
}

# The name of the service.
output "service_name" {
  description = "The name of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.name
}

# The full ID of the service.
output "service_id" {
  description = "The fully qualified ID of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.id
}

# The latest revision of the service.
output "latest_revision" {
  description = "Name of the latest revision of the service."
  value       = google_cloud_run_v2_service.default.latest_ready_revision
}
