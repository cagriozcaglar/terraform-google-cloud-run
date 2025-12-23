# The fully qualified ID of the Cloud Run service.
output "id" {
  description = "The fully qualified identifier of the Cloud Run service."
  value       = google_cloud_run_v2_service.main.id
}

# The name of the latest revision of the Cloud Run service.
output "latest_revision" {
  description = "The name of the latest ready revision of the service."
  value       = google_cloud_run_v2_service.main.latest_ready_revision
}

# The location of the Cloud Run service.
output "location" {
  description = "The location of the Cloud Run service."
  value       = google_cloud_run_v2_service.main.location
}

# The name of the Cloud Run service.
output "name" {
  description = "The name of the Cloud Run service."
  value       = google_cloud_run_v2_service.main.name
}

# The URI of the Cloud Run service.
output "uri" {
  description = "The primary URI of the Cloud Run service."
  value       = google_cloud_run_v2_service.main.uri
}
