# The main.tf file contains the core logic for creating the Cloud Run service and its associated IAM policies.
locals {
  # Generate a stable service account ID if a custom name is not provided.
  # The ID must be between 6 and 30 characters. This ensures the generated name is valid.
  service_account_id = coalesce(var.service_account_name, "run-${substr(var.name, 0, 26)}")

  # Determine the final service account email to use for the Cloud Run service.
  # If `create_service_account` is true, it uses the email of the newly created service account.
  # Otherwise, it uses the email provided in `service_account_email`.
  service_account_email = var.create_service_account ? one(google_service_account.main[*].email) : var.service_account_email

  # Create a map of secret volumes for easier iteration in dynamic blocks.
  # The key is the mount_path to ensure uniqueness.
  secret_volumes_map = { for v in var.secret_volumes : v.mount_path => v }
}

#
# Dedicated Service Account (Optional)
# This resource creates a new, dedicated IAM Service Account for the Cloud Run service.
# Creating a dedicated service account is an IAM best practice for least privilege.
#
resource "google_service_account" "main" {
  # Conditionally creates this resource based on the create_service_account variable.
  count = var.create_service_account ? 1 : 0

  # The GCP project ID. If null, the provider project is used.
  project = var.project_id
  # The unique ID for the service account.
  account_id = local.service_account_id
  # A human-readable name for the service account.
  display_name = "Cloud Run Service Account for ${var.name}"
}

#
# Main Cloud Run v2 Service Resource
# This resource defines the configuration for the Cloud Run service,
# including its container, scaling, networking, and security settings.
#
resource "google_cloud_run_v2_service" "main" {
  # The GCP project ID. If null, the provider project is used.
  project = var.project_id
  # The GCP region where the service will be located.
  location = var.location
  # The name of the Cloud Run service.
  name = var.name
  # Annotations to apply to the service.
  annotations = var.service_annotations
  # Labels to apply to the service.
  labels = var.labels
  # Ingress traffic control setting.
  ingress = var.ingress
  # Disables the default *.run.app URL.
  default_uri_disabled = var.default_uri_disabled
  # The launch stage of the service.
  launch_stage = "GA"

  # The template for the service's revisions.
  template {
    # Annotations to apply to the revision template.
    annotations = var.template_annotations
    # The service account the container runs as.
    service_account = local.service_account_email
    # Scaling configuration for the service.
    scaling {
      # Minimum number of container instances.
      min_instance_count = var.scaling.min_instance_count
      # Maximum number of container instances.
      max_instance_count = var.scaling.max_instance_count
    }
    # Maximum concurrent requests per container instance.
    max_instance_request_concurrency = var.scaling.max_instance_request_concurrency
    # Sets the execution environment to Gen2 for enhanced features.
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"

    #
    # VPC Access configuration for connecting to private resources.
    # This block is only included if a VPC connector is specified.
    #
    dynamic "vpc_access" {
      for_each = var.vpc_connector != null ? [1] : []
      content {
        connector = var.vpc_connector
        egress    = var.vpc_egress
      }
    }

    #
    # Secret volumes for mounting secrets as files.
    # This block iterates through the secret_volumes variable to create volume definitions.
    # A stable name is generated from a hash of the mount_path for robustness.
    #
    dynamic "volumes" {
      for_each = local.secret_volumes_map
      content {
        name = "secret-vol-${substr(sha1(volumes.key), 0, 10)}"
        secret {
          secret = volumes.value.secret_name
          items {
            version = volumes.value.secret_version
            path    = basename(volumes.value.mount_path)
          }
        }
      }
    }

    # Container-specific configuration.
    containers {
      # The container image URL.
      image = var.container_image
      # The command to run in the container.
      command = var.container_command
      # Arguments for the container command.
      args = var.container_args

      #
      # Plaintext environment variables.
      # This block iterates through the env_vars variable to create environment variable definitions.
      #
      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.value.name
          value = env.value.value
        }
      }

      #
      # Secret environment variables from Secret Manager.
      # This block iterates through the secret_env_vars variable to create environment variable definitions
      # that source their values from Secret Manager.
      #
      dynamic "env" {
        for_each = var.secret_env_vars
        content {
          name = env.value.env_var_name
          value_source {
            secret_key_ref {
              secret  = env.value.secret_name
              version = env.value.secret_version
            }
          }
        }
      }

      # Resource limits for the container.
      resources {
        limits            = var.resources
        cpu_idle          = var.cpu_idle
        startup_cpu_boost = var.startup_cpu_boost
      }

      # Ports exposed by the container.
      ports {
        # The port the container listens on.
        container_port = var.container_port
        # The name of the port, required to be 'http1' for Cloud Run.
        name = "http1"
      }

      #
      # Volume mounts for secrets.
      # This block maps the previously defined volumes to mount paths inside the container.
      #
      dynamic "volume_mounts" {
        for_each = local.secret_volumes_map
        content {
          name       = "secret-vol-${substr(sha1(volume_mounts.key), 0, 10)}"
          mount_path = dirname(volume_mounts.key)
        }
      }

      #
      # Startup probe to check if the container has started successfully.
      # This block is only included if startup_probe is configured.
      #
      dynamic "startup_probe" {
        for_each = var.startup_probe != null ? [var.startup_probe] : []
        content {
          initial_delay_seconds = startup_probe.value.initial_delay_seconds
          timeout_seconds       = startup_probe.value.timeout_seconds
          period_seconds        = startup_probe.value.period_seconds
          failure_threshold     = startup_probe.value.failure_threshold
          # Only create the http_get block if a path is specified to avoid sending an empty block to the API.
          dynamic "http_get" {
            for_each = startup_probe.value.http_get_path != null ? [1] : []
            content {
              path = startup_probe.value.http_get_path
            }
          }
        }
      }

      #
      # Liveness probe to check if the container is still running and responsive.
      # This block is only included if liveness_probe is configured.
      #
      dynamic "liveness_probe" {
        for_each = var.liveness_probe != null ? [var.liveness_probe] : []
        content {
          initial_delay_seconds = liveness_probe.value.initial_delay_seconds
          timeout_seconds       = liveness_probe.value.timeout_seconds
          period_seconds        = liveness_probe.value.period_seconds
          failure_threshold     = liveness_probe.value.failure_threshold
          # Only create the http_get block if a path is specified to avoid sending an empty block to the API.
          dynamic "http_get" {
            for_each = liveness_probe.value.http_get_path != null ? [1] : []
            content {
              path = liveness_probe.value.http_get_path
            }
          }
        }
      }
    }
  }

  # This lifecycle block contains configurations for the resource's behavior.
  lifecycle {
    # This precondition enforces the IAM best practice of using a dedicated service account.
    precondition {
      condition     = local.service_account_email != null
      error_message = "A dedicated service account is required. Set `create_service_account` to true or provide a value for `service_account_email`. Using the default Compute Engine service account is not recommended for security reasons."
    }
    # The Terraform HCL parser does not support ignoring specific map keys (e.g., individual annotations).
    # The previous attempt to do so with string literals was syntactically incorrect and caused plan failures.
    # While this may result in some "plan noise" from provider-managed annotations, it is the correct
    # approach to ensure that user-managed annotations in var.service_annotations and var.template_annotations
    # remain manageable through Terraform.
    ignore_changes = []
  }
}

#
# IAM Member for Public Access
# This resource grants public access to the Cloud Run service if
# the `allow_unauthenticated` variable is set to true.
#
resource "google_cloud_run_v2_service_iam_member" "allow_unauthenticated" {
  # Conditionally creates this resource based on the allow_unauthenticated variable.
  count = var.allow_unauthenticated ? 1 : 0

  # The project ID of the service.
  project = google_cloud_run_v2_service.main.project
  # The location of the service.
  location = google_cloud_run_v2_service.main.location
  # The name of the service to apply the IAM policy to.
  name = google_cloud_run_v2_service.main.name
  # The IAM role to grant. 'roles/run.invoker' allows invoking the service.
  role = "roles/run.invoker"
  # The member to grant the role to. 'allUsers' represents any user on the internet.
  member = "allUsers"
}
