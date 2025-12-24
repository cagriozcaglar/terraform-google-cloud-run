# A local variable to determine if the module should create resources.
# This is used to allow the module to be planned without providing required variables.
locals {
  enabled = var.project_id != null && var.name != null && var.location != null && var.image != null
}

# The main resource block that defines the Google Cloud Run v2 service.
# This resource manages the lifecycle of the Cloud Run service, including its configuration,
# container image, scaling, and networking settings.
resource "google_cloud_run_v2_service" "main" {
  # A conditional count to create the resource only when all required variables are provided.
  count = local.enabled ? 1 : 0

  # The project ID in which the resource belongs.
  project = var.project_id
  # The name of the Cloud Run service.
  name = var.name
  # The location of the cloud run service
  location = var.location
  # Controls who can send requests to this service.
  ingress = var.ingress
  # Specifies the launch stage of the Cloud Run service. Defaults to GA.
  launch_stage = "GA"

  # The template for the revision.
  # This block defines the configuration for new revisions of the service.
  template {
    # The email address of the IAM service account associated with the revision.
    service_account = var.service_account_email
    # The maximum number of concurrent requests that can be sent to a single instance.
    max_instance_request_concurrency = var.scaling.max_instance_request_concurrency
    # Defines the execution environment for the container.
    # Can be 'EXECUTION_ENVIRONMENT_GEN1' or 'EXECUTION_ENVIRONMENT_GEN2'.
    execution_environment = var.execution_environment

    # Scaling settings for the service.
    scaling {
      # Minimum number of instances for the service. Set to 1 or higher for latency-critical applications to avoid cold starts.
      min_instance_count = var.scaling.min_instance_count
      # Maximum number of instances for the service.
      max_instance_count = var.scaling.max_instance_count
    }

    # VPC Access configuration for the service.
    # This dynamic block is only included if a vpc_access configuration is provided.
    dynamic "vpc_access" {
      for_each = var.vpc_access != null ? [var.vpc_access] : []
      content {
        # The resource name of the Serverless VPC Access connector.
        connector = vpc_access.value.connector
        # Specifies the traffic egress policy. 'PRIVATE_RANGES_ONLY' is recommended for most use cases to avoid NAT gateway costs.
        egress = vpc_access.value.egress
      }
    }

    # Defines the volumes that can be mounted by containers.
    # This is the recommended way to expose secrets to the application, as files are less prone to leakage than environment variables.
    dynamic "volumes" {
      for_each = var.secret_volumes
      content {
        # The name of the volume.
        name = volumes.key
        # The configuration for a volume that is backed by a Secret Manager secret.
        secret {
          # The name of the secret in Secret Manager.
          secret = volumes.value.secret
          # The items (secret versions) to mount as files.
          dynamic "items" {
            for_each = volumes.value.items
            content {
              # The version of the secret to mount.
              version = items.value.version
              # The relative path of the file to mount the secret version at.
              path = items.value.path
              # The file mode for the mounted secret file.
              mode = items.value.mode
            }
          }
        }
      }
    }

    # Holds the single container that defines the service.
    containers {
      # The URL of the container image. It is a best practice to use images from Artifact Registry (e.g., 'us-central1-docker.pkg.dev/project/repo/image').
      image = var.image
      # The entrypoint for the container. If not specified, the container's default entrypoint is used.
      command = var.container_command
      # The arguments to the entrypoint.
      args = var.container_args

      # Defines the ports that the container listens on.
      ports {
        # The port number the container listens on.
        container_port = var.container_port
      }

      # Defines the resources allocated to the container.
      # Explicitly setting CPU and memory limits is a cost-optimization best practice.
      resources {
        # Specifies whether the CPU should be allocated only when processing a request. Set to false for background tasks.
        cpu_idle = var.resources.cpu_idle
        # Specifies whether to boost CPU allocation during container startup. This can significantly reduce cold start time.
        startup_cpu_boost = var.resources.startup_cpu_boost
        # The CPU and memory limits for the container.
        limits = var.resources.limits
      }

      # Mounts a volume into the container's filesystem.
      dynamic "volume_mounts" {
        for_each = var.volume_mounts
        content {
          # The name of the volume to mount, which must match a name defined in the 'volumes' block.
          name = volume_mounts.key
          # The path within the container at which the volume should be mounted.
          mount_path = volume_mounts.value
        }
      }

      # A dynamic block to configure plain-text environment variables.
      dynamic "env" {
        for_each = var.env_vars
        content {
          # The name of the environment variable.
          name = env.key
          # The value of the environment variable.
          value = env.value
        }
      }

      # A dynamic block to configure environment variables sourced from Secret Manager.
      dynamic "env" {
        for_each = var.secret_env_vars
        content {
          # The name of the environment variable.
          name = env.key
          # The source of the environment variable's value.
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

      # The startup probe checks if the application has started successfully.
      # Crucial for applications with slow start times to prevent them from being terminated prematurely.
      dynamic "startup_probe" {
        for_each = var.startup_probe != null ? [var.startup_probe] : []
        content {
          # Number of seconds after the container has started before the probe is initiated.
          initial_delay_seconds = startup_probe.value.initial_delay_seconds
          # Number of seconds after which the probe times out.
          timeout_seconds = startup_probe.value.timeout_seconds
          # How often (in seconds) to perform the probe.
          period_seconds = startup_probe.value.period_seconds
          # Minimum consecutive failures for the probe to be considered failed.
          failure_threshold = startup_probe.value.failure_threshold
          # The HTTP GET request to perform for the probe.
          http_get {
            # The path to access on the HTTP server.
            path = startup_probe.value.http_get_path
          }
        }
      }

      # The liveness probe checks if the container is still running and responsive.
      # If the probe fails, the container is restarted. Essential for service reliability.
      dynamic "liveness_probe" {
        for_each = var.liveness_probe != null ? [var.liveness_probe] : []
        content {
          # Number of seconds after the container has started before the probe is initiated.
          initial_delay_seconds = liveness_probe.value.initial_delay_seconds
          # Number of seconds after which the probe times out.
          timeout_seconds = liveness_probe.value.timeout_seconds
          # How often (in seconds) to perform the probe.
          period_seconds = liveness_probe.value.period_seconds
          # Minimum consecutive failures for the probe to be considered failed.
          failure_threshold = liveness_probe.value.failure_threshold
          # The HTTP GET request to perform for the probe.
          http_get {
            # The path to access on the HTTP server.
            path = liveness_probe.value.http_get_path
          }
        }
      }
    }
  }
}

# This resource manages IAM policy for the Cloud Run service to allow unauthenticated invocations.
# It is only created if the 'allow_unauthenticated' variable is set to true and the service is enabled.
resource "google_cloud_run_v2_service_iam_member" "invoker" {
  # The number of instances to create. 0 if unauthenticated access is not allowed or the service is disabled, 1 otherwise.
  count = local.enabled && var.allow_unauthenticated ? 1 : 0
  # The project ID of the service.
  project = google_cloud_run_v2_service.main[0].project
  # The location of the service.
  location = google_cloud_run_v2_service.main[0].location
  # The name of the service.
  name = google_cloud_run_v2_service.main[0].name
  # The IAM role to grant. 'roles/run.invoker' allows invoking the service.
  role = "roles/run.invoker"
  # The principal to grant the role to. 'allUsers' represents any user on the internet.
  member = "allUsers"
}

# This resource maps a custom domain to the Cloud Run service.
# It iterates over the list of provided domain names and creates a mapping for each.
resource "google_cloud_run_domain_mapping" "main" {
  # Creates one domain mapping for each domain name in the input list, only if the service is enabled.
  for_each = local.enabled ? toset(var.domain_mappings) : toset([])
  # The project ID where the domain mapping will be created.
  project = google_cloud_run_v2_service.main[0].project
  # The location of the domain mapping, which must match the service's location.
  location = google_cloud_run_v2_service.main[0].location
  # The custom domain name to map.
  name = each.key
  # The specification for the domain mapping.
  spec {
    # The name of the Cloud Run service to map the domain to.
    route_name = google_cloud_run_v2_service.main[0].name
  }
}
