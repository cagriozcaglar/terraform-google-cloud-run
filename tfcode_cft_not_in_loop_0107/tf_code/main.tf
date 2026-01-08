locals {
  # Flatten the iam_members map into a list of objects for use in for_each.
  # This allows creating a separate iam_member resource for each member-role pair.
  iam_bindings_flat = flatten([
    for role, members in var.iam_members : [
      for member in members : {
        # Create a unique key for each binding to use in for_each.
        key    = "${role}-${member}"
        role   = role
        member = member
      }
    ]
  ])

  # Combine plain-text and secret environment variables into a single list of objects.
  # This unified structure allows a single dynamic "env" block to handle both types.
  all_env_vars = concat(
    [
      for env in var.env_vars : {
        name         = env.name
        value        = env.value
        value_source = null # Placeholder for plain-text variables
      }
    ],
    [
      for env in var.secret_env_vars : {
        name  = env.name
        value = null # value and value_source are mutually exclusive
        value_source = {
          secret_key_ref = {
            secret  = env.secret
            version = env.version
          }
        }
      }
    ]
  )
}

# The main resource for the Cloud Run v2 Service.
# This resource defines the service's configuration, including networking,
# scaling, and the container revision template.
resource "google_cloud_run_v2_service" "default" {
  # The user-defined name for the service.
  name = var.name

  # The Google Cloud project and location for deployment.
  project  = var.project_id
  location = var.location

  # An optional description for the service.
  description = var.description
  # A map of labels to apply to the service.
  labels = var.labels
  # A map of annotations to apply to the service.
  annotations = var.annotations

  # Ingress controls who can access the service.
  # Best practice for internal services is INGRESS_TRAFFIC_INTERNAL_ONLY
  # or INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER.
  ingress = var.ingress

  # When true, the default '*.run.app' URL is disabled. Recommended when using
  # a custom domain with a load balancer.
  default_uri_disabled = var.default_uri_disabled

  # A list of custom audiences to be used in authentication.
  custom_audiences = var.custom_audiences

  # Launch stage of the service.
  launch_stage = "GA"

  template {
    # The dedicated service account for the service revision.
    # Using a specific service account follows the principle of least privilege.
    service_account = var.service_account

    # Autoscaling parameters to control how the service scales in response to traffic.
    scaling {
      min_instance_count = var.min_instance_count
      max_instance_count = var.max_instance_count
    }

    # The maximum number of concurrent requests an instance can receive.
    max_instance_request_concurrency = var.max_instance_request_concurrency

    # Request timeout for the container. The value must be a string with an 's' suffix.
    timeout = "${var.request_timeout_seconds}s"

    # Enables session affinity for the service.
    session_affinity = var.session_affinity

    # The CMEK key to use for encryption.
    encryption_key = var.encryption_key

    # Execution environment for the container. GEN2 is recommended.
    execution_environment = var.execution_environment

    # Dynamic block to configure VPC Access connector if specified.
    dynamic "vpc_access" {
      for_each = var.vpc_access != null ? [var.vpc_access] : []
      content {
        # The full identifier of the Serverless VPC Access connector.
        connector = vpc_access.value.connector

        # Egress settings. Best practice is PRIVATE_RANGES_ONLY unless a static
        # egress IP through a NAT gateway is required.
        egress = vpc_access.value.egress
      }
    }

    # Dynamic block to define volumes from secrets.
    # This is the most secure method for providing credentials to a service.
    dynamic "volumes" {
      for_each = var.secret_volumes
      content {
        # A user-defined name for the volume.
        name = volumes.key

        # The secret to mount. The Cloud Run service agent requires the
        # 'Secret Manager Secret Accessor' role on this secret.
        secret {
          secret = volumes.value.secret
          dynamic "items" {
            for_each = volumes.value.items
            content {
              # The filename to create within the mount path.
              path = items.key
              # The version of the secret to mount.
              version = items.value
            }
          }
        }
      }
    }

    # The container specification for this service revision.
    containers {
      # The container image to deploy.
      image = var.image

      # Defines the container's resource requests and limits.
      # Explicitly setting these is a cost-control best practice.
      resources {
        limits            = var.container_resources != null ? var.container_resources.limits : null
        cpu_idle          = var.cpu_idle
        startup_cpu_boost = var.startup_cpu_boost
      }

      # The port the container listens on for incoming requests.
      ports {
        name           = "http1"
        container_port = var.container_port
      }

      # A list of arguments to the container's entrypoint.
      args = var.container_args

      # The entrypoint for the container.
      command = var.container_command

      # Dynamic block to add environment variables, both plain-text and from Secret Manager.
      dynamic "env" {
        for_each = local.all_env_vars
        content {
          name  = env.value.name
          value = env.value.value

          # This dynamic block is only rendered for secret-based environment variables
          # where value_source is not null. It correctly creates the nested block structure.
          dynamic "value_source" {
            for_each = env.value.value_source != null ? [env.value.value_source] : []
            content {
              secret_key_ref {
                secret  = value_source.value.secret_key_ref.secret
                version = value_source.value.secret_key_ref.version
              }
            }
          }
        }
      }

      # Dynamic block to mount secret volumes into the container's filesystem.
      dynamic "volume_mounts" {
        for_each = var.secret_volumes
        content {
          # The name of the volume to mount, matching a name from the 'volumes' block.
          name = volume_mounts.key

          # The path inside the container where the volume should be mounted.
          mount_path = volume_mounts.value.mount_path
        }
      }

      # Dynamic block for the startup probe, crucial for services with long startup times.
      dynamic "startup_probe" {
        for_each = var.startup_probe != null ? [var.startup_probe] : []
        content {
          initial_delay_seconds = lookup(startup_probe.value, "initial_delay_seconds", null)
          timeout_seconds       = lookup(startup_probe.value, "timeout_seconds", 1)
          period_seconds        = lookup(startup_probe.value, "period_seconds", 10)
          failure_threshold     = lookup(startup_probe.value, "failure_threshold", 3)

          # HTTP health check configuration.
          dynamic "http_get" {
            for_each = lookup(startup_probe.value, "http_get", null) != null ? [startup_probe.value.http_get] : []
            content {
              path = http_get.value.path
              port = lookup(http_get.value, "port", var.container_port)
            }
          }

          # TCP health check configuration.
          dynamic "tcp_socket" {
            for_each = lookup(startup_probe.value, "tcp_socket", null) != null ? [startup_probe.value.tcp_socket] : []
            content {
              port = tcp_socket.value.port
            }
          }

          # gRPC health check configuration.
          dynamic "grpc" {
            for_each = lookup(startup_probe.value, "grpc", null) != null ? [startup_probe.value.grpc] : []
            content {
              port    = grpc.value.port
              service = lookup(grpc.value, "service", null)
            }
          }
        }
      }

      # Dynamic block for the liveness probe to detect and restart unresponsive containers.
      dynamic "liveness_probe" {
        for_each = var.liveness_probe != null ? [var.liveness_probe] : []
        content {
          initial_delay_seconds = lookup(liveness_probe.value, "initial_delay_seconds", null)
          timeout_seconds       = lookup(liveness_probe.value, "timeout_seconds", 1)
          period_seconds        = lookup(liveness_probe.value, "period_seconds", 10)
          failure_threshold     = lookup(liveness_probe.value, "failure_threshold", 3)

          # HTTP health check configuration.
          dynamic "http_get" {
            for_each = lookup(liveness_probe.value, "http_get", null) != null ? [liveness_probe.value.http_get] : []
            content {
              path = http_get.value.path
              port = lookup(http_get.value, "port", var.container_port)
            }
          }

          # TCP health check configuration.
          dynamic "tcp_socket" {
            for_each = lookup(liveness_probe.value, "tcp_socket", null) != null ? [liveness_probe.value.tcp_socket] : []
            content {
              port = tcp_socket.value.port
            }
          }

          # gRPC health check configuration.
          dynamic "grpc" {
            for_each = lookup(liveness_probe.value, "grpc", null) != null ? [liveness_probe.value.grpc] : []
            content {
              port    = grpc.value.port
              service = lookup(grpc.value, "service", null)
            }
          }
        }
      }
    }
  }
}

# This resource manages individual IAM role memberships for the Cloud Run service.
# Using 'iam_member' is non-authoritative and safer than 'iam_binding' or 'iam_policy'
# as it does not remove existing bindings.
resource "google_cloud_run_v2_service_iam_member" "default" {
  # Create one resource for each role-member pair defined in var.iam_members.
  for_each = { for binding in local.iam_bindings_flat : binding.key => binding }

  # The location and name of the Cloud Run service.
  location = google_cloud_run_v2_service.default.location
  name     = google_cloud_run_v2_service.default.name
  project  = google_cloud_run_v2_service.default.project

  # The IAM role to grant.
  role = each.value.role

  # The member to grant the role to (e.g., 'allUsers', 'serviceAccount:...')
  member = each.value.member
}
