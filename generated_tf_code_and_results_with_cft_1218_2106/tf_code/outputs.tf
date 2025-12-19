# The ID of the Cloud Run service.
output "id" {
  description = "The fully qualified identifier of the Cloud Run service."
  value       = google_cloud_run_v2_service.main.id
}

# The latest ready revision of the Cloud Run service.
output "latest_ready_revision" {
  description = "Name of the latest revision that is serving traffic."
  value       = google_cloud_run_v2_service.main.latest_ready_revision
}

# The location of the Cloud Run service.
output "location" {
  description = "The location where the Cloud Run service was deployed."
  value       = google_cloud_run_v2_service.main.location
}

# The name of the Cloud Run service.
output "name" {
  description = "The name of the Cloud Run service."
  value       = google_cloud_run_v2_service.main.name
}

# The project of the Cloud Run service.
output "project" {
  description = "The project ID where the Cloud Run service was deployed."
  value       = google_cloud_run_v2_service.main.project
}

# The URI of the Cloud Run service.
output "uri" {
  description = "The primary public URI of the Cloud Run service."
  value       = google_cloud_run_v2_service.main.uri
}
