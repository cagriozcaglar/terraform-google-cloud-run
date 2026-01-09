# This Terraform module provides a comprehensive and secure way to deploy services
# to Google Cloud Run (v2). It is designed with enterprise best practices in mind,
# including least-privilege service accounts, secure secret management, fine-grained
# ingress/egress control, and detailed health checks. The module supports both
# simple public APIs and complex internal microservices connected to a VPC.
#
# <!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
# <!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

locals {
  # Determine the service account email to use for the Cloud Run service.
  # If a new SA is created, use its email; otherwise, use the provided one.
  service_account_email = var.service_account_create ? one(google_service_account.service_identity[*].email) : var.service_account_email

  # Create a unified set of secret names from both env vars and volumes
  # to grant IAM permissions efficiently and without duplication.
  all_secrets = toset(concat(
    [for s in var.secret_env_vars : s.secret_name],
    [for v in var.secret_volumes : v.secret_name]
  ))

  # Create a map of secrets to their parsed project and secret IDs.
  # This allows using short names for secrets in the same project or
  # full resource IDs (projects/PROJECT/secrets/SECRET) for cross-project access.
  parsed_secrets = { for s in local.all_secrets : s => {
    project   = length(split("/", s)) > 3 ? split("/", s)[1] : var.project_id
    secret_id = element(split("/", s), -1)
  } }

  # Create a map of secret volume mount paths to valid Cloud Run volume names.
  # The name must be 1-63 characters long, contain only lowercase letters, numbers,
  # and dashes, start with a letter and not end with a dash.
  # A hash is appended to ensure uniqueness if truncation causes collisions.
  secret_volume_names = {
    for k, v in var.secret_volumes : k => trimsuffix(substr(
      "s-${replace(lower(element(split("/", v.secret_name), -1)), "[^a-z0-9]+", "-")}-${substr(sha1(v.secret_name), 0, 8)}",
      0,
      63
    ), "-")
  }
}

# A dedicated service account for the Cloud Run service to run as.
# This follows the principle of least privilege.
resource "google_service_account" "service_identity" {
  # Create this resource only if the user has requested it.
  count = var.service_account_create ? 1 : 0

  # The GCP project ID. If not provided, the provider project is used.
  project = var.project_id
  # A unique ID for the service account. Must be between 6 and 30 characters and lowercase.
  account_id = "${lower(var.service_name)}-sa"
  # A user-friendly name for the service account.
  display_name = "Service Account for Cloud Run service ${var.service_name}"

  lifecycle {
    precondition {
      # This precondition validates that the service_name length is valid for creating
      # a service account ID. The generated ID is "${var.service_name}-sa", which must be
      # between 6 and 30 characters long.
      condition     = length(var.service_name) >= 4 && length(var.service_name) <= 27
      error_message = "When service_account_create is true, the service_name length must be between 4 and 27 characters to generate a valid service account ID."
    }
  }
}

# The core Cloud Run service resource.
resource "google_cloud_run_v2_service" "default" {
  # The GCP project ID. If not provided, the provider project is used.
  project = var.project_id
  # The name of the service.
  name = var.service_name
  # The GCP region for the service.
  location = var.location

  # The ingress settings control how the service is reached.
  ingress = var.ingress

  # Defines the template for new revisions of the service.
  template {
    # If true, disables the default '*.run.app' URL. This is a security best
    # practice when the service is only exposed via a Load Balancer.
    labels = var.default_uri_disabled ? { "run.googleapis.com/default-uri-disabled" = "true" } : null

    # The dedicated service account for this revision.
    service_account = local.service_account_email
    # The timeout for responding to a request.
    timeout = "${var.request_timeout_seconds}s"

    # Defines the scaling parameters for the service.
    scaling {
      # The minimum number of instances to keep warm.
      min_instance_count = var.min_instance_count
      # The maximum number of instances to scale out to.
      max_instance_count = var.max_instance_count
    }

    # If specified, connects the service to a VPC network.
    dynamic "vpc_access" {
      for_each = var.vpc_access != null ? [var.vpc_access] : []
      iterator = vpc
      content {
        # The full resource ID of the Serverless VPC Access connector.
        connector = vpc.value.connector_id
        # Controls the routing of egress traffic. 'PRIVATE_RANGES_ONLY' is recommended
        # to avoid routing public internet traffic through the VPC and incurring NAT costs.
        egress = vpc.value.egress
      }
    }

    # Configuration for the primary container.
    containers {
      # The Artifact Registry URL for the container image.
      image = var.container_image
      # The command to run in the container.
      command = var.container_command
      # The arguments for the container command.
      args = var.container_args

      # The network port the container listens on.
      ports {
        container_port = var.container_port
      }

      # CPU and memory resource limits for the container.
      resources {
        # Specifies if the CPU is allocated only when processing requests.
        cpu_idle = var.cpu_idle
        # Enables CPU boost during startup to reduce cold starts.
        startup_cpu_boost = var.startup_cpu_boost
        # The configured CPU and memory limits.
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
      }

      # Defines plaintext environment variables.
      dynamic "env" {
        for_each = var.env_vars
        iterator = env
        content {
          # The name of the environment variable.
          name = env.key
          # The value of the environment variable.
          value = env.value
        }
      }

      # Defines environment variables sourced from Secret Manager.
      dynamic "env" {
        for_each = var.secret_env_vars
        iterator = secret_env
        content {
          # The name of the environment variable.
          name = secret_env.key
          # The source of the value, which is a secret.
          value_source {
            secret_key_ref {
              # The name of the secret in Secret Manager.
              secret = secret_env.value.secret_name
              # The specific version of the secret to use.
              version = secret_env.value.secret_version
            }
          }
        }
      }

      # Mounts the volumes defined in the template into the container's filesystem.
      dynamic "volume_mounts" {
        for_each = var.secret_volumes
        iterator = mount
        content {
          # The name of the volume to mount, must match a name in the `volumes` block.
          name = local.secret_volume_names[mount.key]
          # The path inside the container where the volume should be mounted.
          mount_path = mount.key
        }
      }

      # Health check to determine if the container has started successfully.
      dynamic "startup_probe" {
        for_each = var.startup_probe != null ? [var.startup_probe] : []
        iterator = probe
        content {
          # Delay before starting the probe.
          initial_delay_seconds = probe.value.initial_delay_seconds
          # Seconds to wait for a probe to respond.
          timeout_seconds = probe.value.timeout_seconds
          # How often to perform the probe.
          period_seconds = probe.value.period_seconds
          # Number of failures before marking the container as failed.
          failure_threshold = probe.value.failure_threshold
          # The HTTP GET request configuration for the probe.
          http_get {
            # The path to probe (e.g., '/healthz/startup').
            path = probe.value.http_get_path
            # The port to probe. Defaults to the container port.
            port = probe.value.http_get_port
          }
        }
      }

      # Health check to determine if the container is still responsive.
      dynamic "liveness_probe" {
        for_each = var.liveness_probe != null ? [var.liveness_probe] : []
        iterator = probe
        content {
          # Delay before starting the probe.
          initial_delay_seconds = probe.value.initial_delay_seconds
          # Seconds to wait for a probe to respond.
          timeout_seconds = probe.value.timeout_seconds
          # How often to perform the probe.
          period_seconds = probe.value.period_seconds
          # Number of failures before restarting the container.
          failure_threshold = probe.value.failure_threshold
          # The HTTP GET request configuration for the probe.
          http_get {
            # The path to probe (e.g., '/healthz/live').
            path = probe.value.http_get_path
            # The port to probe. Defaults to the container port.
            port = probe.value.http_get_port
          }
        }
      }
    }

    # Defines volumes that can be mounted into containers.
    dynamic "volumes" {
      for_each = var.secret_volumes
      iterator = vol
      content {
        # The name of the volume.
        name = local.secret_volume_names[vol.key]
        # The secret to mount.
        secret {
          # The name of the secret in Secret Manager.
          secret = vol.value.secret_name
          # Defines which secret versions to mount as files.
          dynamic "items" {
            for_each = vol.value.items
            iterator = item
            content {
              # The filename to mount the secret version's content to.
              path = item.key
              # The specific version of the secret to use.
              version = item.value
            }
          }
        }
      }
    }
  }

  lifecycle {
    precondition {
      # This precondition validates that if a service account is not being created by the module,
      # an existing service account's email must be provided. This check cannot be done in the
      # variable validation block because it references another variable.
      condition     = var.service_account_create || var.service_account_email != null
      error_message = "If service_account_create is false, a service_account_email must be provided."
    }
  }
}

# IAM policy bindings to allow specified members to invoke the Cloud Run service.
resource "google_cloud_run_v2_service_iam_member" "invoker" {
  # Create one binding for each member in the 'invokers' list.
  for_each = toset(var.invokers)

  # The GCP project ID of the service.
  project = google_cloud_run_v2_service.default.project
  # The name of the service.
  name = google_cloud_run_v2_service.default.name
  # The GCP region of the service.
  location = google_cloud_run_v2_service.default.location
  # The IAM role to grant.
  role = "roles/run.invoker"
  # The IAM member (e.g., 'allUsers', 'serviceAccount:...').
  member = each.key
}

# IAM policy to grant the Cloud Run service's service account access to all referenced secrets.
resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  # Create one binding for each unique secret name from env vars and volumes.
  for_each = local.parsed_secrets

  # The GCP project ID where the secret resides. If not provided, the provider project is used.
  project = each.value.project
  # The name of the secret.
  secret_id = each.value.secret_id
  # The role to grant, allowing the SA to access the secret's value.
  role = "roles/secretmanager.secretAccessor"
  # The member to grant the role to, which is the Cloud Run service's SA.
  member = "serviceAccount:${local.service_account_email}"
}
