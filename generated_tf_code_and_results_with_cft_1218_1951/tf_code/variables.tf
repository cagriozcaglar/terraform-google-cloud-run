# This file is automatically managed by terraform-docs.
# Do not edit manually.
# <!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
variable "name" {
  description = "The name of the Cloud Run service."
  type        = string
  default     = "cloud-run-service-name"
}

variable "project_id" {
  description = "The Google Cloud project ID to deploy the service to."
  type        = string
  default     = "gcp-project-id"
}

variable "location" {
  description = "The Google Cloud location (region) to deploy the service in."
  type        = string
  default     = "us-central1"
}

variable "image" {
  description = "The full URL of the container image to deploy. It is recommended to use an image from Artifact Registry."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "generate_service_account" {
  description = "If true, a dedicated service account will be created for the Cloud Run service. This is a security best practice."
  type        = bool
  default     = true
}

variable "service_account_name" {
  description = "The name of the dedicated service account to create for this service. If `generate_service_account` is true, this name will be used. Must be between 6 and 30 characters."
  type        = string
  default     = null
}

variable "service_account_email" {
  description = "The email of an existing service account to use. If `generate_service_account` is false and this is not provided, the default compute service account will be used."
  type        = string
  default     = null
}

variable "iam_members" {
  description = "A map of IAM roles to a list of members to grant to the service. For example, to make the service public: `{\"roles/run.invoker\" = [\"allUsers\"]}`."
  type        = map(list(string))
  default     = {}
}

variable "ingress" {
  description = "Controls who can reach the service. Valid values are INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER."
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "container_port" {
  description = "The port number that the container listens on for incoming requests."
  type        = number
  default     = 8080
}

variable "container_command" {
  description = "Overrides the entrypoint of the container image. If not specified, the container's default entrypoint is used."
  type        = list(string)
  default     = null
}

variable "container_args" {
  description = "Arguments to the entrypoint. If not specified, the container's default CMD is used."
  type        = list(string)
  default     = null
}

variable "resources" {
  description = "A map defining the CPU and memory limits for the container. Billing is based on allocation, so set these to the minimum required values to optimize costs."
  type        = map(string)
  default = {
    cpu    = "1"
    memory = "512Mi"
  }
}

variable "env_vars" {
  description = "A map of plaintext environment variables to set in the container. Avoid using this for secrets."
  type        = map(string)
  default     = {}
}

variable "secret_env_vars" {
  description = "A map of environment variables sourced from Secret Manager. The key is the environment variable name, and the value is an object with `secret` (the secret name) and `version` (e.g., 'latest'). Note: Mounting secrets as volumes is generally more secure."
  type = map(object({
    secret  = string
    version = string
  }))
  default = {}
}

variable "secret_volumes" {
  description = "A map to configure secrets to be mounted as files. This is the recommended way to handle secrets. The key is a logical name for the volume, and the value is an object with `secret` (the secret name), `mount_path` (e.g., '/etc/secrets'), and `items` (a map of filename to secret version)."
  type = map(object({
    secret     = string
    mount_path = string
    items      = map(string)
  }))
  default = {}
}

variable "scaling" {
  description = "Autoscaling settings for the service. `min_instance_count` should be set to 1 or higher for latency-sensitive applications to avoid cold starts."
  type = object({
    min_instance_count = number
    max_instance_count = number
  })
  default = {
    min_instance_count = 0
    max_instance_count = 100
  }
}

variable "max_instance_request_concurrency" {
  description = "The maximum number of concurrent requests that can be sent to a single instance. Tune for I/O-bound (higher) vs. CPU-bound (lower) workloads."
  type        = number
  default     = 80
}

variable "startup_cpu_boost" {
  description = "If true, temporarily boosts CPU allocation during instance startup to reduce cold start latency. This is a performance best practice."
  type        = bool
  default     = true
}

variable "cpu_idle" {
  description = "If true (default), CPU is only allocated during request processing (request-based billing). If false, CPU is allocated for the entire container instance lifecycle (instance-based billing). Set to false only if reliable background processing is required after a request is served."
  type        = bool
  default     = true
}

variable "startup_probe" {
  description = "Configuration for a startup probe to check if the container has started successfully. Essential for applications with slow startup times."
  type = object({
    initial_delay_seconds = optional(number)
    timeout_seconds       = optional(number, 1)
    period_seconds        = optional(number, 10)
    failure_threshold     = optional(number, 3)
    http_get_path         = optional(string)
    tcp_socket_port       = optional(number)
  })
  default = null
}

variable "liveness_probe" {
  description = "Configuration for a liveness probe to check if the container is still responsive. If the probe fails, the container is restarted. Essential for service reliability."
  type = object({
    initial_delay_seconds = optional(number)
    timeout_seconds       = optional(number, 1)
    period_seconds        = optional(number, 10)
    failure_threshold     = optional(number, 3)
    http_get_path         = optional(string)
  })
  default = null
}

variable "vpc_access_connector" {
  description = "The full resource ID of the Serverless VPC Access connector to use. Example: `projects/my-project/locations/us-central1/connectors/my-connector`."
  type        = string
  default     = null
}

variable "vpc_access_egress" {
  description = "The egress setting for VPC outbound traffic. `PRIVATE_RANGES_ONLY` is the recommended default. Use `ALL_TRAFFIC` only if a static egress IP via Cloud NAT is a strict requirement."
  type        = string
  default     = "PRIVATE_RANGES_ONLY"
}
