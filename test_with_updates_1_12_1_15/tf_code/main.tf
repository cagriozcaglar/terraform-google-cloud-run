locals {
  # Combine plaintext and secret-based environment variables into a single list for the resource
  all_env_vars = concat(
    [for env in var.env_vars : {
      name  = env.name
      value = env.value
      value_source = null
      }],
    [for secret_env in var.secret_env_vars : {
      name  = secret_env.name
      value = null
      value_source = {
        secret_key_ref = {
          secret  = secret_env.secret
          version = secret_env.version
        }
      }
      }]
  )
  # Flatten the IAM members map to create a unique list of role/member pairs.
  # This is necessary for using the additive google_cloud_run_v2_service_iam_member resource, which is a security best practice.
  iam_members_flat = flatten([
    for role, members in var.iam_members : [
      for member in members : {
        role   = role
        member = member
      }
    ]
  ])
}

#
# Cloud Run v2 Service Resource
#
resource "google_cloud_run_v2_service" "main" {
  # The GCP Project ID to deploy the service in.
  project = var.project_id
  # The GCP region for the service.
  location = var.location
  # The name of the Cloud Run service.
  name = var.name
  # Specifies ingress traffic controls.
  ingress = var.ingress
  # Disables the default *.run.app URL when set.
  default_uri_disabled = var.default_uri_disabled

  template {
    # The dedicated service account for the service, enforcing least privilege.
    service_account = var.service_account_email
    # The number of concurrent requests an instance can receive.
    max_instance_request_concurrency = var.max_instance_request_concurrency

    scaling {
      # Minimum number of instances to keep warm.
      min_instance_count = var.min_instance_count
      # Maximum number of instances to scale out to.
      max_instance_count = var.max_instance_count
    }

    # Dynamically configure VPC Access if a connector is provided.
    dynamic "vpc_access" {
      for_each = var.vpc_access != null ? [var.vpc_access] : []
      content {
        # The resource name of the VPC Access connector.
        connector = vpc_access.value.connector
        # Defines network egress routing. Defaults to PRIVATE_RANGES_ONLY.
        egress = vpc_access.value.egress
      }
    }

    # Dynamically define volumes from secrets.
    dynamic "volumes" {
      for_each = var.secret_volumes
      content {
        # The name of the volume.
        name = volumes.value.name
        secret {
          # The name (ID) of the secret in Secret Manager.
          secret = volumes.value.secret
          items {
            # The version of the secret to mount.
            version = volumes.value.version
            # The path within the volume to mount the secret data. Using the secret name as the path if not specified.
            path = coalesce(volumes.value.path, basename(volumes.value.secret))
          }
        }
      }
    }

    containers {
      # The container image to deploy.
      image = var.image
      # The command to execute when the container starts.
      command = var.container_command
      # Arguments for the container's command.
      args = var.container_args

      # Define container-level resource limits for cost and performance control.
      resources {
        limits = var.container_resources_limits
        # Controls CPU allocation: true for request-based billing, false for instance-based billing.
        cpu_idle = var.cpu_idle
        # Boosts CPU during container startup to reduce cold starts.
        startup_cpu_boost = var.startup_cpu_boost
      }

      ports {
        # The port the container listens on.
        container_port = var.container_port
      }

      # Dynamically configure environment variables from all sources.
      dynamic "env" {
        for_each = local.all_env_vars
        content {
          # The name of the environment variable.
          name = env.value.name
          # The plaintext value of the environment variable (if applicable).
          value = env.value.value
          # Dynamically configure the value source if it's from Secret Manager.
          dynamic "value_source" {
            for_each = env.value.value_source != null ? [env.value.value_source] : []
            content {
              secret_key_ref {
                # The name (ID) of the secret in Secret Manager.
                secret = value_source.value.secret_key_ref.secret
                # The version of the secret.
                version = value_source.value.secret_key_ref.version
              }
            }
          }
        }
      }

      # Dynamically mount secret volumes into the container's filesystem.
      dynamic "volume_mounts" {
        for_each = var.secret_volumes
        content {
          # The name of the volume to mount.
          name = volume_mounts.value.name
          # The path inside the container where the volume should be mounted.
          mount_path = volume_mounts.value.mount_path
        }
      }

      # Dynamically configure the startup probe if a path or port is defined.
      dynamic "startup_probe" {
        for_each = var.startup_probe.http_get_path != null || var.startup_probe.tcp_socket_port != null ? [var.startup_probe] : []
        content {
          # Number of seconds to wait before the first probe.
          initial_delay_seconds = startup_probe.value.initial_delay_seconds
          # Number of seconds after which the probe times out.
          timeout_seconds = startup_probe.value.timeout_seconds
          # How often (in seconds) to perform the probe.
          period_seconds = startup_probe.value.period_seconds
          # Minimum consecutive failures for the probe to be considered failed.
          failure_threshold = startup_probe.value.failure_threshold
          # Dynamically add an HTTP GET probe if a path is specified.
          dynamic "http_get" {
            for_each = startup_probe.value.http_get_path != null ? [startup_probe.value.http_get_path] : []
            content {
              # The path to access for the health check.
              path = http_get.value
            }
          }
          # Dynamically add a TCP socket probe if a port is specified.
          dynamic "tcp_socket" {
            for_each = startup_probe.value.tcp_socket_port != null ? [startup_probe.value.tcp_socket_port] : []
            content {
              # The port to probe.
              port = tcp_socket.value
            }
          }
        }
      }

      # Dynamically configure the liveness probe if a path or port is defined.
      dynamic "liveness_probe" {
        for_each = var.liveness_probe.http_get_path != null || var.liveness_probe.tcp_socket_port != null ? [var.liveness_probe] : []
        content {
          # Number of seconds to wait before the first probe.
          initial_delay_seconds = liveness_probe.value.initial_delay_seconds
          # Number of seconds after which the probe times out.
          timeout_seconds = liveness_probe.value.timeout_seconds
          # How often (in seconds) to perform the probe.
          period_seconds = liveness_probe.value.period_seconds
          # Minimum consecutive failures for the probe to be considered failed.
          failure_threshold = liveness_probe.value.failure_threshold
          # Dynamically add an HTTP GET probe if a path is specified.
          dynamic "http_get" {
            for_each = liveness_probe.value.http_get_path != null ? [liveness_probe.value.http_get_path] : []
            content {
              # The path to access for the health check.
              path = http_get.value
            }
          }
          # Dynamically add a TCP socket probe if a port is specified.
          dynamic "tcp_socket" {
            for_each = liveness_probe.value.tcp_socket_port != null ? [liveness_probe.value.tcp_socket_port] : []
            content {
              # The port to probe.
              port = tcp_socket.value
            }
          }
        }
      }
    }
  }

  traffic {
    # Route 100% of traffic to the latest revision.
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

#
# IAM Memberships for the Cloud Run Service
# Using iam_member is a best practice as it's additive and avoids conflicts with other IAM management tools.
#
resource "google_cloud_run_v2_service_iam_member" "main" {
  # Create a unique key for each role/member pair to iterate over.
  for_each = { for binding in local.iam_members_flat : "${binding.role}/${binding.member}" => binding }
  # The GCP Project ID where the service is located.
  project = google_cloud_run_v2_service.main.project
  # The GCP region where the service is located.
  location = google_cloud_run_v2_service.main.location
  # The name of the Cloud Run service.
  name = google_cloud_run_v2_service.main.name
  # The IAM role to grant.
  role = each.value.role
  # The member to grant the role to.
  member = each.value.member
}
