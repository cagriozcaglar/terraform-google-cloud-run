variable "project_id" {
  description = "The Google Cloud project ID to deploy the Cloud Run service in. If not specified, the provider's project will be used."
  type        = string
  default     = null
}

variable "location" {
  description = "The Google Cloud region to deploy the Cloud Run service in."
  type        = string
  default     = "us-central1"
}

variable "name" {
  description = "The name of the Cloud Run service."
  type        = string
  default     = "cloud-run-service"
}

variable "image" {
  description = "The container image to deploy. It is a best practice to use an image from Artifact Registry (e.g., 'us-central1-docker.pkg.dev/my-project/my-repo/my-image:tag') as Container Registry is deprecated."
  type        = string
  default     = "us-run.pkg.dev/cloudrun/container/hello"
}

variable "service_account_email" {
  description = "The email of the dedicated IAM Service Account to run the service. This enforces the principle of least privilege. If not specified, the default compute service account is used."
  type        = string
  default     = null
}

variable "ingress" {
  description = "Controls who can reach the service. For services behind a Load Balancer, use 'INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER'. For internal-only services, use 'INGRESS_TRAFFIC_INTERNAL_ONLY'. Use 'INGRESS_TRAFFIC_ALL' for public services."
  type        = string
  default     = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
}

variable "default_uri_disabled" {
  description = "When true, disables the default '*.run.app' URL. This is a security best practice when the service is only accessed through a Load Balancer or custom domain, preventing users from bypassing security controls."
  type        = bool
  default     = true
}

variable "min_instance_count" {
  description = "The minimum number of container instances to keep running. Set to 1 or higher for latency-critical applications to reduce cold starts."
  type        = number
  default     = 0
}

variable "max_instance_count" {
  description = "The maximum number of container instances that can be started. This is a key cost-control setting."
  type        = number
  default     = 100
}

variable "max_instance_request_concurrency" {
  description = "The maximum number of concurrent requests that a single container instance can receive. Tune based on workload: high for I/O-bound, lower for CPU-bound."
  type        = number
  default     = 80
}

variable "cpu_idle" {
  description = "Controls CPU allocation and billing. 'true' (Request-based billing) throttles CPU when no requests are processing and is cost-effective for APIs. 'false' (Instance-based billing) keeps CPU always allocated and is required for reliable background processing."
  type        = bool
  default     = true
}

variable "startup_cpu_boost" {
  description = "When true, temporarily doubles the allocated CPU during container startup to reduce cold start latency."
  type        = bool
  default     = true
}

variable "container_port" {
  description = "The port that the container listens on for incoming requests."
  type        = number
  default     = 8080
}

variable "container_command" {
  description = "The command to run when the container starts. If not specified, the container's default entrypoint is used."
  type        = list(string)
  default     = null
}

variable "container_args" {
  description = "The arguments to pass to the container's command."
  type        = list(string)
  default     = null
}

variable "container_resources_limits" {
  description = "A map of resource limits for the container. Set explicit limits to the minimum required size to optimize costs. Billing is based on allocation."
  type        = map(string)
  default = {
    "cpu"    = "1"
    "memory" = "512Mi"
  }
}

variable "env_vars" {
  description = "A list of plaintext environment variables to set in the container."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "secret_env_vars" {
  description = "A list of environment variables sourced from Secret Manager. Each object specifies the environment variable name, the secret name (ID), and the secret version."
  type = list(object({
    name    = string
    secret  = string
    version = string
  }))
  default = []
}

variable "secret_volumes" {
  description = "A list of secrets to mount as volumes (files) in the container. This is a secure method for injecting credentials or configuration files. Each object specifies the volume name, mount path, secret name (ID), version, and the filename."
  type = list(object({
    name       = string
    mount_path = string
    secret     = string
    version    = string
    path       = optional(string)
  }))
  default = []
}

variable "vpc_access" {
  description = "Configuration for VPC Access Connector. The 'egress' setting defaults to 'PRIVATE_RANGES_ONLY', which is optimal for accessing private resources like Cloud SQL without routing all public traffic through the VPC and requiring a NAT gateway."
  type = object({
    connector = string
    egress    = optional(string, "PRIVATE_RANGES_ONLY")
  })
  default = null
}

variable "startup_probe" {
  description = "Health check to determine if the container has started successfully. Crucial for applications with slow startup times to avoid being killed prematurely. Set 'initial_delay_seconds' to allow sufficient time for initialization."
  type = object({
    initial_delay_seconds = optional(number, 0)
    timeout_seconds       = optional(number, 1)
    period_seconds        = optional(number, 10)
    failure_threshold     = optional(number, 3)
    http_get_path         = optional(string)
    tcp_socket_port       = optional(number)
  })
  default = {}
}

variable "liveness_probe" {
  description = "Health check to determine if the container is still responsive. If this probe fails, Cloud Run will restart the container instance."
  type = object({
    initial_delay_seconds = optional(number, 0)
    timeout_seconds       = optional(number, 1)
    period_seconds        = optional(number, 10)
    failure_threshold     = optional(number, 3)
    http_get_path         = optional(string)
    tcp_socket_port       = optional(number)
  })
  default = {}
}

variable "iam_members" {
  description = "A map of IAM roles to a list of members to grant access to the service. Example to make public: `{\"roles/run.invoker\" = [\"allUsers\"]}`. Example for a specific service account: `{\"roles/run.invoker\" = [\"serviceAccount:my-invoker@my-project.iam.gserviceaccount.com\"]}`."
  type        = map(list(string))
  default     = {}
}
