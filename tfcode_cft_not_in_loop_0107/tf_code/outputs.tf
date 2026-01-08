output "latest_ready_revision" {
  description = "The name of the latest revision of the service that is ready to serve traffic."
  value       = google_cloud_run_v2_service.default.latest_ready_revision
}

output "service_id" {
  description = "The fully qualified ID of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.id
}

output "service_name" {
  description = "The name of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.name
}

output "uri" {
  description = "The public URI of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.uri
}
