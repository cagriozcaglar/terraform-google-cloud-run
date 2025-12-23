# The variables.tf file defines the input parameters for the module.

#
# Service Identity & Location
# Basic identification and location for the Cloud Run service.
#
variable "name" {
  description = "The name of the Cloud Run service."
  type        = string
  # A default value is provided to allow for out-of-the-box testing.
  # For production use, this should be explicitly set to a unique name for the service.
  default = "cloud-run-v2-service-example"
}

variable "project_id" {
  description = "The Google Cloud project ID where the service will be deployed. If null, the provider project is used."
  type        = string
  default     = null
}

variable "location" {
  description = "The Google Cloud region for the Cloud Run service."
  type        = string
  # A default value is provided to allow for out-of-the-box testing.
  # For production use, this should be explicitly set to the desired region.
  default = "us-central1"
}

#
# Container Configuration
# Define the container image and its runtime settings.
#
variable "container_image" {
  description = "The container image to deploy. It is recommended to use an image from Artifact Registry, as Container Registry is deprecated."
  type        = string
  # A default value is provided to allow for out-of-the-box testing and deployment of a sample application.
  # For production use, this variable should be explicitly set to your container image.
  default = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "container_command" {
  description = "An optional list of strings specifying the command to run within the container."
  type        = list(string)
  default     = []
}

variable "container_args" {
  description = "An optional list of strings specifying arguments to the container command."
  type        = list(string)
  default     = []
}

variable "container_port" {
  description = "The port number that the container listens on for requests."
  type        = number
  default     = 8080
}

variable "env_vars" {
  description = "A list of objects representing plaintext environment variables to set in the container. Each object should have 'name' and 'value' keys."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

#
# Resource Management
# Configure CPU, memory, and scaling for the service.
#
variable "resources" {
  description = "A map defining the CPU and memory resource limits for the container. Billing is based on allocation, so set these to the minimum required values."
  type = map(string)
  default = {
    "cpu"    = "1"
    "memory" = "512Mi"
  }
}

variable "scaling" {
  description = "Configuration for the scaling behavior of the service, including min/max instances and concurrency."
  type = object({
    min_instance_count               = optional(number, 0)
    max_instance_count               = optional(number, 100)
    max_instance_request_concurrency = optional(number, 80)
  })
  default = {}
}

variable "cpu_idle" {
  description = "If true (request-based billing), CPU is only allocated during request processing. Set to false (instance-based billing) only if the service needs to perform background tasks after responding to a request."
  type        = bool
  default     = true
}

variable "startup_cpu_boost" {
  description = "If true, temporarily boosts the CPU allocation during container startup to reduce cold start latency. Recommended for latency-critical applications."
  type        = bool
  default     = false
}

#
# Security & Networking
# Control network access and traffic flow.
#
variable "ingress" {
  description = "Controls who can reach the Cloud Run service. Valid values are 'INGRESS_TRAFFIC_ALL', 'INGRESS_TRAFFIC_INTERNAL_ONLY', 'INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER'."
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
  validation {
    condition     = contains(["INGRESS_TRAFFIC_ALL", "INGRESS_TRAFFIC_INTERNAL_ONLY", "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"], var.ingress)
    error_message = "Valid values for ingress are 'INGRESS_TRAFFIC_ALL', 'INGRESS_TRAFFIC_INTERNAL_ONLY', or 'INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER'."
  }
}

variable "vpc_connector" {
  description = "The self-link or ID of the Serverless VPC Access connector to use for this service."
  type        = string
  default     = null
}

variable "vpc_egress" {
  description = "The egress setting for the VPC connector. 'PRIVATE_RANGES_ONLY' is the recommended default. Use 'ALL_TRAFFIC' only when a static egress IP via Cloud NAT is a strict requirement."
  type        = string
  default     = "PRIVATE_RANGES_ONLY"
  validation {
    condition     = contains(["PRIVATE_RANGES_ONLY", "ALL_TRAFFIC"], var.vpc_egress)
    error_message = "Valid values for vpc_egress are 'PRIVATE_RANGES_ONLY' or 'ALL_TRAFFIC'."
  }
}

variable "default_uri_disabled" {
  description = "If true, the default `*.run.app` URL is disabled. This is a security best practice when the service is behind a Load Balancer to prevent bypassing security controls."
  type        = bool
  default     = false
}

variable "allow_unauthenticated" {
  description = "If set to true, grants the 'roles/run.invoker' role to 'allUsers', allowing public, unauthenticated access to the service."
  type        = bool
  default     = false
}

#
# Service Account
# Manage the IAM identity for the Cloud Run service.
#
variable "create_service_account" {
  description = "If true, a new dedicated service account is created for the service. If false, `service_account_email` must be provided. Defaults to true as a security best practice."
  type        = bool
  default     = true
}

variable "service_account_email" {
  description = "The email address of the IAM Service Account to run the service. Best practice is to use a dedicated service account with least-privilege IAM roles. This is required if `create_service_account` is false."
  type        = string
  default     = null
}

variable "service_account_name" {
  description = "The `account_id` of the service account to create, used only if `create_service_account` is true. If not provided, a name will be generated based on the service name."
  type        = string
  default     = null
}

#
# Secrets Integration
# Securely inject secrets from Secret Manager as environment variables or mounted files.
#
variable "secret_env_vars" {
  description = "A list of objects for secrets to be exposed as environment variables. Each object should define 'env_var_name', 'secret_name', and 'secret_version'. The service account must have the 'Secret Manager Secret Accessor' role for each secret."
  type = list(object({
    env_var_name   = string
    secret_name    = string
    secret_version = string
  }))
  default = []
}

variable "secret_volumes" {
  description = "A list of objects for secrets to be mounted as files. This is the most secure method for handling credentials. Each object must define 'mount_path', 'secret_name', and 'secret_version'. The service account must have the 'Secret Manager Secret Accessor' role for each secret."
  type = list(object({
    mount_path     = string
    secret_name    = string
    secret_version = string
  }))
  default = []
  validation {
    condition     = length(var.secret_volumes) < 2 ? true : length(toset([for v in var.secret_volumes : dirname(v.mount_path)])) == length(var.secret_volumes)
    error_message = "All secret_volumes entries must result in unique mount directories. Each secret is mounted in its own volume, and the Cloud Run API does not allow multiple volume mounts to the same directory path. Two or more entries in your list resolve to the same directory."
  }
}

#
# Health Checks
# Configure probes to monitor container health and readiness.
#
variable "startup_probe" {
  description = "Startup probe configuration. Crucial for services with long initialization times to prevent them from being killed before they are ready."
  type = object({
    http_get_path         = optional(string)
    initial_delay_seconds = optional(number)
    timeout_seconds       = optional(number)
    period_seconds        = optional(number)
    failure_threshold     = optional(number)
  })
  default = null
}

variable "liveness_probe" {
  description = "Liveness probe configuration. Essential for ensuring the service is automatically restarted if it becomes unresponsive or deadlocked."
  type = object({
    http_get_path         = optional(string)
    initial_delay_seconds = optional(number)
    timeout_seconds       = optional(number)
    period_seconds        = optional(number)
    failure_threshold     = optional(number)
  })
  default = null
}

#
# Metadata
# Set labels and annotations for the service and its revisions.
#
variable "labels" {
  description = "A map of key-value string pairs to assign as labels to the service."
  type        = map(string)
  default     = {}
}

variable "service_annotations" {
  description = "A map of key-value string pairs to assign as annotations to the service."
  type        = map(string)
  default     = {}
}

variable "template_annotations" {
  description = "A map of key-value string pairs to assign as annotations to the revision template."
  type        = map(string)
  default     = {}
}
