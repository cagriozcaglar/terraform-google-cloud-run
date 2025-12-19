locals {
  # Determine the service account email to use for the Cloud Run service.
  # If a SA name is provided and generation is enabled, use the generated SA's email.
  # Otherwise, fall back to the explicitly provided SA email.
  service_account_email = var.generate_service_account && var.service_account_name != null ? one(google_service_account.this[*].email) : var.service_account_email

  # Check if the service is configured to use any secrets from Secret Manager.
  uses_secrets = length(var.secret_env_vars) > 0 || length(var.secret_volumes) > 0
}

# Create a dedicated Service Account for the Cloud Run service.
# This is a security best practice, enforcing the principle of least privilege.
resource "google_service_account" "this" {
  # Create this resource only if SA generation is enabled and a name is provided.
  count = var.generate_service_account && var.service_account_name != null ? 1 : 0

  # The ID of the project in which the service account will be created.
  project = var.project_id

  # The account ID to use for the service account.
  account_id = var.service_account_name

  # A brief, human-readable name for the service account.
  display_name = "Service Account for Cloud Run service ${var.name}"
}

# Grant the service account permission to access secrets if the service is configured to use them.
# This is required for the Cloud Run service to pull secret values at runtime.
resource "google_project_iam_member" "secret_accessor" {
  # Create this binding only if a service account is being used and secrets are configured.
  count = local.service_account_email != null && local.uses_secrets ? 1 : 0

  # The ID of the project where the IAM policy is applied.
  project = var.project_id

  # The role granting permission to access secret values.
  role = "roles/secretmanager.secretAccessor"

  # The member to grant the role to. This applies to both generated and provided service accounts.
  member = "serviceAccount:${local.service_account_email}"
}

# The primary resource for defining the Cloud Run service, its container, and configuration.
resource "google_cloud_run_v2_service" "main" {
  # The name of the Cloud Run service.
  name = var.name

  # The Google Cloud project ID.
  project = var.project_id

  # The location (region) for the service.
  location = var.location

  # Configuration for ingress traffic control.
  ingress = var.ingress

  # The template for the service revision.
  template {
    # The email of the service account to be used by the revision.
    service_account = local.service_account_email

    # Autoscaling configuration for the service.
    scaling {
      min_instance_count = var.scaling.min_instance_count
      max_instance_count = var.scaling.max_instance_count
    }

    # The maximum number of concurrent requests an instance can handle.
    max_instance_request_concurrency = var.max_instance_request_concurrency

    # VPC Access configuration.
    dynamic "vpc_access" {
      # This block is only included if a VPC connector is specified.
      for_each = var.vpc_access_connector != null ? [1] : []
      content {
        # The resource ID of the Serverless VPC Access connector.
        connector = var.vpc_access_connector
        # The egress traffic setting.
        egress = var.vpc_access_egress
      }
    }

    # The containers that belong to this service.
    containers {
      # The URL of the container image.
      image = var.image

      # Override the container's entrypoint.
      command = var.container_command
      # Arguments for the container's entrypoint.
      args = var.container_args

      # The port the container listens on.
      ports {
        container_port = var.container_port
      }

      # Resource allocation for the container.
      resources {
        # CPU and memory limits.
        limits = var.resources
        # Enables startup CPU boost for faster cold starts.
        startup_cpu_boost = var.startup_cpu_boost
        # If true, CPU is only allocated during request processing.
        cpu_idle = var.cpu_idle
      }

      # Plaintext environment variables.
      dynamic "env" {
        for_each = var.env_vars
        content {
          # The name of the environment variable.
          name = env.key
          # The value of the environment variable.
          value = env.value
        }
      }

      # Environment variables sourced from Secret Manager.
      dynamic "env" {
        for_each = var.secret_env_vars
        content {
          # The name of the environment variable.
          name = env.key
          # The source of the value is a secret.
          value_source {
            secret_key_ref {
              # The name of the secret in Secret Manager.
              secret = env.value.secret
              # The version of the secret to use.
              version = env.value.version
            }
          }
        }
      }

      # Mounts for volumes defined below.
      dynamic "volume_mounts" {
        for_each = var.secret_volumes
        content {
          # The name of the volume to mount.
          name = volume_mounts.key
          # The path within the container to mount the volume.
          mount_path = volume_mounts.value.mount_path
        }
      }

      # Startup probe for health checking during initialization.
      dynamic "startup_probe" {
        for_each = var.startup_probe != null ? [var.startup_probe] : []
        content {
          # Number of seconds after container start before probes are initiated.
          initial_delay_seconds = startup_probe.value.initial_delay_seconds
          # Number of seconds after which the probe times out.
          timeout_seconds = startup_probe.value.timeout_seconds
          # How often (in seconds) to perform the probe.
          period_seconds = startup_probe.value.period_seconds
          # Minimum consecutive failures for the probe to be considered failed.
          failure_threshold = startup_probe.value.failure_threshold
          # HTTP GET request probe.
          dynamic "http_get" {
            for_each = lookup(startup_probe.value, "http_get_path", null) != null ? [1] : []
            content {
              # The path to access for the health check.
              path = startup_probe.value.http_get_path
            }
          }
          # TCP socket probe.
          dynamic "tcp_socket" {
            for_each = lookup(startup_probe.value, "tcp_socket_port", null) != null ? [1] : []
            content {
              # The port number to connect to.
              port = startup_probe.value.tcp_socket_port
            }
          }
        }
      }

      # Liveness probe for ongoing health checking.
      dynamic "liveness_probe" {
        for_each = var.liveness_probe != null ? [var.liveness_probe] : []
        content {
          # Number of seconds after container start before probes are initiated.
          initial_delay_seconds = liveness_probe.value.initial_delay_seconds
          # Number of seconds after which the probe times out.
          timeout_seconds = liveness_probe.value.timeout_seconds
          # How often (in seconds) to perform the probe.
          period_seconds = liveness_probe.value.period_seconds
          # Minimum consecutive failures for the probe to be considered failed.
          failure_threshold = liveness_probe.value.failure_threshold
          # HTTP GET request probe.
          dynamic "http_get" {
            for_each = lookup(liveness_probe.value, "http_get_path", null) != null ? [1] : []
            content {
              # The path to access for the health check.
              path = liveness_probe.value.http_get_path
            }
          }
        }
      }
    }

    # Volume definitions, sourcing data from secrets.
    dynamic "volumes" {
      for_each = var.secret_volumes
      content {
        # The name of the volume.
        name = volumes.key
        # The secret to mount.
        secret {
          # The name of the secret in Secret Manager.
          secret = volumes.value.secret
          # The items from the secret to mount as files.
          dynamic "items" {
            for_each = volumes.value.items
            content {
              # The relative path of the file to mount to.
              path = items.key
              # The version of the secret to mount.
              version = items.value
            }
          }
        }
      }
    }
  }
}

# Manages IAM bindings for the Cloud Run service.
resource "google_cloud_run_v2_service_iam_binding" "main" {
  # Iterate over each role specified in the iam_members variable.
  for_each = var.iam_members

  # The project ID of the service.
  project = google_cloud_run_v2_service.main.project
  # The location of the service.
  location = google_cloud_run_v2_service.main.location
  # The name of the service.
  name = google_cloud_run_v2_service.main.name

  # The IAM role to grant.
  role = each.key
  # The list of members to grant the role to.
  members = each.value
}
