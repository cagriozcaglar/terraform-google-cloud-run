# The locals block is used to define local variables within a module.
locals {
  # Flattens the IAM bindings map to a list of objects, making it suitable for
  # creating individual iam_member resources for each role-member pair. This
  # provides a more granular and additive approach to managing IAM policies.
  iam_members_flat = flatten([
    for role, members in var.iam_bindings : [
      for member in members : {
        # Creates a unique key for the for_each loop.
        key    = "${role}/${member}"
        role   = role
        member = member
      }
    ]
  ])
}

# The google_cloud_run_v2_service resource creates and manages a Cloud Run v2 service.
# This is the central resource of the module, defining the container image, scaling,
# security, and networking configuration for the serverless application.
resource "google_cloud_run_v2_service" "main" {
  # The GCP project ID where the service will be deployed.
  project = var.project_id
  # The GCP region for the Cloud Run service.
  location = var.location
  # The name of the Cloud Run service.
  name = var.name
  # User-defined annotations to apply to the Service.
  annotations = var.annotations
  # User-defined labels to apply to the Service.
  labels = var.labels
  # The launch stage of the service.
  launch_stage = var.launch_stage
  # Specifies the ingress traffic policy.
  ingress = var.ingress

  # The template for the service's revision.
  template {
    # A list of containers that defines the revision.
    containers {
      # The URL of the container image in Artifact Registry or another registry.
      image = var.image
      # Entrypoint array. Not executed within a shell.
      command = var.container_command
      # Arguments to the entrypoint. The container image's CMD is used if this is not provided.
      args = var.container_args
      # Defines the resources (CPU, memory) allocated to the container.
      resources {
        # A map of resource limits for this container.
        limits = var.container_resources.limits
      }
      # A list of ports that can be reached within the container.
      ports {
        # The port number your container listens on.
        container_port = var.container_port
      }

      # Dynamic block for plaintext environment variables.
      dynamic "env" {
        # Iterates over the map of environment variables provided in var.env_vars.
        for_each = var.env_vars
        # Defines the content of each 'env' block.
        content {
          # The name of the environment variable.
          name = env.key
          # The value of the environment variable.
          value = env.value
        }
      }

      # Dynamic block for environment variables sourced from Secret Manager.
      dynamic "env" {
        # Iterates over the map of secret environment variables.
        for_each = var.secret_env_vars
        # Defines the content of each 'env' block.
        content {
          # The name of the environment variable.
          name = env.key
          # The source for the environment variable's value.
          value_source {
            # Specifies that the value comes from a secret in Secret Manager.
            secret_key_ref {
              # The name of the secret in Secret Manager.
              secret = env.value.secret
              # The version of the secret to use.
              version = env.value.version
            }
          }
        }
      }

      # Dynamic block to configure the startup probe for health checking.
      dynamic "startup_probe" {
        # This block is only created if a startup_probe object is provided.
        for_each = var.startup_probe != null ? [var.startup_probe] : []
        # Defines the content of the startup_probe block.
        content {
          # Number of seconds after the container has started before the probe is initiated.
          initial_delay_seconds = startup_probe.value.initial_delay_seconds
          # Number of seconds after which the probe times out.
          timeout_seconds = startup_probe.value.timeout_seconds
          # Minimum consecutive failures for the probe to be considered failed.
          failure_threshold = startup_probe.value.failure_threshold
          # How often (in seconds) to perform the probe.
          period_seconds = startup_probe.value.period_seconds
          # Defines an HTTP GET request for the probe if specified.
          http_get {
            # The path to access on the HTTP server. Defaults to "/" if not specified.
            path = try(startup_probe.value.http_get.path, "/")
          }
        }
      }

      # Dynamic block to configure the liveness probe for health checking.
      dynamic "liveness_probe" {
        # This block is only created if a liveness_probe object is provided.
        for_each = var.liveness_probe != null ? [var.liveness_probe] : []
        # Defines the content of the liveness_probe block.
        content {
          # Number of seconds after the container has started before the probe is initiated.
          initial_delay_seconds = liveness_probe.value.initial_delay_seconds
          # Number of seconds after which the probe times out.
          timeout_seconds = liveness_probe.value.timeout_seconds
          # Minimum consecutive failures for the probe to be considered failed.
          failure_threshold = liveness_probe.value.failure_threshold
          # How often (in seconds) to perform the probe.
          period_seconds = liveness_probe.value.period_seconds
          # Defines an HTTP GET request for the probe if specified.
          http_get {
            # The path to access on the HTTP server. Defaults to "/" if not specified.
            path = try(liveness_probe.value.http_get.path, "/")
          }
        }
      }

      # Dynamic block for mounting secrets as volumes (files).
      dynamic "volume_mounts" {
        # Iterates over the map of secret volumes.
        for_each = var.secret_volumes
        # Defines the content of the volume_mounts block.
        content {
          # The name of the volume to mount, which must match a name in the 'volumes' block.
          name = volume_mounts.key
          # The path within the container at which the volume should be mounted.
          mount_path = volume_mounts.value.mount_path
        }
      }
    }

    # Dynamic block for defining volumes sourced from Secret Manager.
    dynamic "volumes" {
      # Iterates over the map of secret volumes.
      for_each = var.secret_volumes
      # Defines the content of the volumes block.
      content {
        # The name of the volume.
        name = volumes.key
        # Specifies that the volume's data comes from a secret.
        secret {
          # The name of the secret in Secret Manager.
          secret = volumes.value.secret
          # Specifies which secret versions to project into the volume.
          dynamic "items" {
            # Iterates over the map of items (files) to create from secret versions.
            for_each = volumes.value.items
            # Defines the content of the items block.
            content {
              # The relative path of the file to project the secret version into.
              path = items.key
              # The version of the secret to project.
              version = items.value
            }
          }
        }
      }
    }

    # The dedicated service account for the revision.
    service_account = var.service_account_email

    # Dynamic block to provide access to a Serverless VPC Access connector.
    dynamic "vpc_access" {
      # This block is only created if a VPC connector is specified.
      for_each = var.vpc_connector != null ? [var.vpc_connector] : []
      # Defines the content of the vpc_access block.
      content {
        # The full name of the VPC Access Connector.
        connector = vpc_access.value
        # The egress traffic configuration.
        egress = var.vpc_egress
      }
    }
    # Scaling settings for the service.
    scaling {
      # The minimum number of container instances that are kept warm.
      min_instance_count = var.min_instance_count
      # The maximum number of container instances that can be started.
      max_instance_count = var.max_instance_count
    }
    # The maximum number of concurrent requests that can be sent to a container instance.
    max_instance_request_concurrency = var.max_instance_request_concurrency
    # Timeout for requests, specified as a string with a unit suffix, e.g., "300s".
    timeout = "${var.timeout_seconds}s"
    # The execution environment for the service.
    execution_environment = var.execution_environment
    # Enables CPU boost during container startup.
    startup_cpu_boost = var.startup_cpu_boost
    # Controls CPU allocation when no requests are being processed.
    cpu_idle = var.cpu_idle
    # Annotations that are applied to this Revision.
    annotations = var.template_annotations
    # Labels that are applied to this Revision.
    labels = var.template_labels
  }

  # Configures the traffic distribution for the service.
  traffic {
    # Specifies the target for traffic.
    type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    # Allocates 100% of traffic to the latest revision.
    percent = 100
  }
}

# The google_cloud_run_v2_service_iam_member resource manages IAM members for a Cloud Run service.
# It additively grants a role to a member, which is safer than iam_binding as it does not
# remove other members from the role.
resource "google_cloud_run_v2_service_iam_member" "iam" {
  # Creates one IAM member resource per role-member pair from the flattened local variable.
  for_each = { for v in local.iam_members_flat : v.key => v }

  # The GCP project ID where the service exists.
  project = var.project_id
  # The GCP region where the service exists.
  location = google_cloud_run_v2_service.main.location
  # The name of the Cloud Run service.
  name = google_cloud_run_v2_service.main.name
  # The IAM role to be applied.
  role = each.value.role
  # The member to be granted the role.
  member = each.value.member
}
