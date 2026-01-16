output "service_id" {
  description = "The fully qualified identifier of the Cloud Run service."
  value       = google_cloud_run_v2_service.main.id
}

output "service_name" {
  description = "The name of the deployed Cloud Run service."
  value       = google_cloud_run_v2_service.main.name
}

output "service_uri" {
  description = "The default URI of the Cloud Run service."
  value       = google_cloud_run_v2_service.main.uri
}

output "latest_ready_revision" {
  description = "The name of the latest revision that is ready to serve traffic."
  value       = google_cloud_run_v2_service.main.latest_ready_revision
}

output "service" {
  description = "The full Cloud Run v2 Service resource object."
  value       = google_cloud_run_v2_service.main
}
