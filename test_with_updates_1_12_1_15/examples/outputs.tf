output "service_name" {
  description = "The name of the deployed Cloud Run service."
  value       = module.cloud_run_service.service_name
}

output "service_uri" {
  description = "The default URI of the Cloud Run service. Will be empty if default_uri_disabled is true."
  value       = module.cloud_run_service.service_uri
}

output "latest_ready_revision" {
  description = "The name of the latest revision that is ready to serve traffic."
  value       = module.cloud_run_service.latest_ready_revision
}

output "service_id" {
  description = "The fully qualified identifier of the Cloud Run service."
  value       = module.cloud_run_service.service_id
}

output "service_account_email" {
  description = "The email of the service account used by the Cloud Run service."
  value       = google_service_account.run_sa.email
}

output "invoker_service_account_email" {
  description = "The email of the service account granted invoker permissions."
  value       = google_service_account.invoker_sa.email
}
