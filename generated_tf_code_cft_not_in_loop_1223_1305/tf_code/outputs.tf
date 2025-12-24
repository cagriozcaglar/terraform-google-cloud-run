# The unique identifier of the Cloud Run service.
output "id" {
  description = "The fully qualified identifier of the Cloud Run service."
  value       = local.enabled ? google_cloud_run_v2_service.main[0].id : null
}

# The name of the Cloud Run service.
output "name" {
  description = "The name of the Cloud Run service."
  value       = local.enabled ? google_cloud_run_v2_service.main[0].name : null
}

# The default URI of the Cloud Run service.
output "uri" {
  description = "The default URI of the Cloud Run service."
  value       = local.enabled ? google_cloud_run_v2_service.main[0].uri : null
}

# The location of the Cloud Run service.
output "location" {
  description = "The location where the Cloud Run service is deployed."
  value       = local.enabled ? google_cloud_run_v2_service.main[0].location : null
}

# The name of the latest ready revision of the Cloud Run service.
output "latest_ready_revision_id" {
  description = "The name of the latest revision of the service that is ready to serve traffic."
  value       = local.enabled ? google_cloud_run_v2_service.main[0].latest_ready_revision : null
}

# The status of the custom domain mappings.
output "domain_mapping_status" {
  description = "A map of custom domain names to their mapping status, including required DNS records. You must configure these DNS records with your domain registrar."
  value       = { for domain, mapping in google_cloud_run_domain_mapping.main : domain => mapping.status }
}
