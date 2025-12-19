# This block defines the main Google Cloud Run v2 service resource.
resource "google_cloud_run_v2_service" "main" {
  # The project ID where the service will be created. If not provided, the provider project will be used.
  project = var.project_id
  # The location (region) where the service will be deployed.
  location = var.location
  # The name of the Cloud Run service.
  name = var.name
  # User-defined labels to organize and identify the service.
  labels = var.labels
  # User-defined annotations. Crucial for features like Cloud SQL integration.
  annotations = var.annotations
  # The ingress traffic configuration for the service. Controls how the service is reached.
  ingress = var.ingress
  # Disables the default *.run.app URL. Recommended when using a custom domain or load balancer with IAP.
  default_uri_disabled = var.default_uri_disabled
  # The launch stage of the Cloud Run service.
  launch_stage = "GA"

  # The template block defines the configuration for a new revision of the service.
  template {
    # The email address of the IAM service account to be used by the service's revision. Enforces least privilege.
    service_account = var.service_account_email
    # The maximum number of concurrent requests an instance can receive.
    max_instance_request_concurrency = var.max_instance_request_concurrency
    # The execution environment for the revision. GEN2 provides better performance and feature support.
    execution_environment = "EXECUTION_ENVIRONMENT_GEN2"

    # Dynamic block for scaling configuration.
    dynamic "scaling" {
      # This block is only created if the scaling variable is not null.
      for_each = var.scaling != null ? [var.scaling] : []
      # The content of the scaling block.
      content {
        # The minimum number of instances to keep running. Set to > 0 to reduce cold starts.
        min_instance_count = scaling.value.min_instance_count
        # The maximum number of instances the service can scale up to.
        max_instance_count = scaling.value.max_instance_count
      }
    }

    # Dynamic block for VPC Access Connector configuration.
    dynamic "vpc_access" {
      # This block is only created if the vpc_access variable is not null.
      for_each = var.vpc_access != null ? [var.vpc_access] : []
      # The content of the vpc_access block.
      content {
        # The resource name of the VPC Access Connector to use.
        connector = vpc_access.value.connector
        # The egress traffic setting. Defaults to PRIVATE_RANGES_ONLY to prevent unnecessary NAT costs.
        egress = vpc_access.value.egress
      }
    }

    # Dynamic block to define volumes from secrets. This is the more secure way to handle credentials.
    dynamic "volumes" {
      # Iterate over the map of secret volumes defined in variables.
      for_each = var.secret_volumes
      # The content of each volume block.
      content {
        # The name of the volume.
        name = volumes.key
        # Defines the secret to be used as the source for this volume.
        secret {
          # The name of the secret in Secret Manager.
          secret = volumes.value.secret
          # Dynamic block for specifying which versions of the secret to mount.
          dynamic "items" {
            # Iterate over the items map for the current secret volume.
            for_each = volumes.value.items
            # The content of each item block.
            content {
              # The secret version to mount.
              version = items.value
              # The relative path within the volume where the secret version will be available.
              path = items.key
            }
          }
        }
      }
    }

    # The containers block defines the containers to run in the service. This module supports one container.
    containers {
      # The Artifact Registry URL of the container image to deploy.
      image = var.image
      # The command to run when the container starts.
      command = var.container_command
      # The arguments to pass to the container's command.
      args = var.container_args

      # The resources block specifies CPU and memory limits for the container.
      resources {
        # The CPU and memory limits. Setting these helps control costs and ensures predictable performance.
        limits = {
          cpu    = var.resources.cpu
          memory = var.resources.memory
        }
        # Enables startup CPU boost to reduce cold start times.
        startup_cpu_boost = var.startup_cpu_boost
      }

      # The ports block specifies the ports the container listens on.
      ports {
        # The port number the container listens on for incoming requests.
        container_port = var.container_port
      }

      # Dynamic block for plaintext environment variables.
      dynamic "env" {
        # Iterate over the map of plaintext environment variables.
        for_each = var.env_vars
        # The content of each env block.
        content {
          # The name of the environment variable.
          name = env.key
          # The value of the environment variable.
          value = env.value
        }
      }

      # Dynamic block for secret-based environment variables.
      dynamic "env" {
        # Iterate over the map of secret environment variables.
        for_each = var.secret_env_vars
        # The content of each env block.
        content {
          # The name of the environment variable.
          name = env.key
          # Defines the secret to be used as the source for this environment variable.
          value_source {
            secret_key_ref {
              # The name of the secret in Secret Manager.
              secret = env.value.secret
              # The version of the secret.
              version = env.value.version
            }
          }
        }
      }

      # Dynamic block for mounting the secret volumes defined above into the container's filesystem.
      dynamic "volume_mounts" {
        # Iterate over the map of secret volumes.
        for_each = var.secret_volumes
        # The content of each volume_mounts block.
        content {
          # The name of the volume to mount, must match a name in the top-level volumes block.
          name = volume_mounts.key
          # The path within the container where the volume should be mounted.
          mount_path = volume_mounts.value.mount_path
        }
      }

      # Dynamic block for the startup probe. Checks if the container has started successfully.
      dynamic "startup_probe" {
        # This block is only created if the startup_probe variable is not null.
        for_each = var.startup_probe != null ? [var.startup_probe] : []
        # The content of the startup_probe block.
        content {
          # The initial delay before the first probe is sent.
          initial_delay_seconds = startup_probe.value.initial_delay_seconds
          # The timeout for each probe attempt.
          timeout_seconds = startup_probe.value.timeout_seconds
          # The period between probe attempts.
          period_seconds = startup_probe.value.period_seconds
          # The number of consecutive failures required to mark the container as failed.
          failure_threshold = startup_probe.value.failure_threshold
          # Defines an HTTP GET probe.
          http_get {
            # The path to send the probe request to.
            path = startup_probe.value.http_get_path
          }
        }
      }

      # Dynamic block for the liveness probe. Checks if the container is still running and responsive.
      dynamic "liveness_probe" {
        # This block is only created if the liveness_probe variable is not null.
        for_each = var.liveness_probe != null ? [var.liveness_probe] : []
        # The content of the liveness_probe block.
        content {
          # The initial delay before the first probe is sent.
          initial_delay_seconds = liveness_probe.value.initial_delay_seconds
          # The timeout for each probe attempt.
          timeout_seconds = liveness_probe.value.timeout_seconds
          # The period between probe attempts.
          period_seconds = liveness_probe.value.period_seconds
          # The number of consecutive failures required to mark the container as failed and restart it.
          failure_threshold = liveness_probe.value.failure_threshold
          # Defines an HTTP GET probe.
          http_get {
            # The path to send the probe request to.
            path = liveness_probe.value.http_get_path
          }
        }
      }
    }
  }
}

# This resource manages IAM permissions for the Cloud Run service, specifically for public access.
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  # This resource is created only if public_access is true.
  count = var.public_access ? 1 : 0
  # The project ID of the service.
  project = google_cloud_run_v2_service.main.project
  # The location of the service.
  location = google_cloud_run_v2_service.main.location
  # The name of the service.
  name = google_cloud_run_v2_service.main.name
  # The IAM role to grant. 'roles/run.invoker' allows invoking the service.
  role = "roles/run.invoker"
  # The principal to grant the role to. 'allUsers' makes the service publicly accessible.
  member = "allUsers"
}
