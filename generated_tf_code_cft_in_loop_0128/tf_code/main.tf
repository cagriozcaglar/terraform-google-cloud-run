# Enable the necessary APIs for the Cloud Run service.
resource "google_project_service" "apis" {
  # A set of Google Cloud services to enable.
  for_each = toset([
    "run.googleapis.com",
    "iam.googleapis.com"
  ])

  # The project to enable the service on. If null, the provider's project is used.
  project = var.project_id
  # The service to enable.
  service = each.key
  # It is recommended to keep APIs enabled to avoid accidental disruption of services.
  disable_on_destroy = false
}

# This resource defines the Google Cloud Run v2 service.
resource "google_cloud_run_v2_service" "default" {
  # The project in which the resource belongs. If null, the provider's project is used.
  project = var.project_id
  # The location of the cloud run service.
  location = var.region
  # The name of the service.
  name = var.service_name

  # The template for the service. This defines the container image, resources, scaling, etc.
  template {
    # The containers to run in the service.
    containers {
      # The container image to deploy.
      image = var.image
      # The ports that the container listens on.
      ports {
        # The port number.
        container_port = var.container_port
      }
      # The resources to allocate to the container.
      resources {
        # The limits for the resources.
        limits = {
          # The CPU limit.
          cpu    = var.cpu_limit
          # The memory limit.
          memory = var.memory_limit
        }
      }
    }

    # The service account to run the container as.
    service_account = var.service_account_email

    # The scaling configuration for the service.
    scaling {
      # The minimum number of container instances.
      min_instance_count = var.min_instance_count
      # The maximum number of container instances.
      max_instance_count = var.max_instance_count
    }

    # The maximum request execution time, specified in seconds.
    timeout = "${var.timeout_seconds}s"
  }

  # This dependency ensures that the necessary APIs are enabled before attempting to create the Cloud Run service.
  depends_on = [google_project_service.apis]
}

# This resource manages the IAM policy for the Cloud Run service to allow public (unauthenticated) access.
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  # A condition to only create this resource if unauthenticated access is allowed.
  count = var.allow_unauthenticated ? 1 : 0

  # The project in which the service belongs.
  project = google_cloud_run_v2_service.default.project
  # The location of the cloud run service.
  location = google_cloud_run_v2_service.default.location
  # The name of the service to apply the IAM policy to.
  name = google_cloud_run_v2_service.default.name
  # The role to grant. 'roles/run.invoker' allows invoking the service.
  role = "roles/run.invoker"
  # The member to grant the role to. 'allUsers' represents anyone on the internet.
  member = "allUsers"
}
