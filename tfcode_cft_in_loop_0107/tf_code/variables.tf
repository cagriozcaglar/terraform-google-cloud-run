variable "container_args" {
  description = "A list of strings representing the arguments to the container command. If not specified, the container's default CMD is used."
  type        = list(string)
  default     = null
}

variable "container_command" {
  description = "A list of strings representing the command to run in the container. If not specified, the container's default ENTRYPOINT is used."
  type        = list(string)
  default     = null
}

variable "container_image" {
  description = "The full URI of the container image to deploy, hosted in Artifact Registry. GCR is deprecated and should not be used for new deployments."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "container_port" {
  description = "The port number that the container listens on for incoming requests."
  type        = number
  default     = 8080
}

variable "cpu_idle" {
  description = "If true (default), CPU is only allocated during request processing (request-based billing). If false, CPU is allocated for the entire container instance lifecycle (instance-based billing), which is required for background processing."
  type        = bool
  default     = true
}

variable "cpu_limit" {
  description = "The maximum amount of CPU to allocate to the container instance, e.g., '1' for 1 vCPU. Billing is based on this allocation."
  type        = string
  default     = "1"
}

variable "default_uri_disabled" {
  description = "If true, disables the default '*.run.app' URL. This is a security best practice when the service is only exposed via a Load Balancer."
  type        = bool
  default     = false
}

variable "env_vars" {
  description = "A map of plaintext environment variables to set in the container, where the key is the variable name and the value is its content."
  type        = map(string)
  default     = {}
}

variable "ingress" {
  description = "Controls who can reach the service. Valid values INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER."
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "invokers" {
  description = "A list of IAM members who should be granted 'roles/run.invoker' permission. For example, `[\"allUsers\", \"serviceAccount:my-invoker@project.iam.gserviceaccount.com\"]`."
  type        = list(string)
  default     = []
}

variable "liveness_probe" {
  description = "Configuration for the liveness probe, which checks if the container is still responsive. If it fails, the container is restarted. It is highly recommended to configure this."
  type = object({
    initial_delay_seconds = optional(number, 0)
    timeout_seconds       = optional(number, 1)
    period_seconds        = optional(number, 10)
    failure_threshold     = optional(number, 3)
    http_get_path         = optional(string, "/")
    http_get_port         = optional(number)
  })
  default = null
}

variable "location" {
  description = "The Google Cloud region to deploy the Cloud Run service in."
  type        = string
  default     = "us-central1"
}

variable "max_instance_count" {
  description = "The maximum number of container instances that the service can scale up to."
  type        = number
  default     = 100
}

variable "memory_limit" {
  description = "The maximum amount of memory to allocate to the container instance, e.g., '512Mi'. Billing is based on this allocation."
  type        = string
  default     = "512Mi"
}

variable "min_instance_count" {
  description = "The minimum number of container instances to keep running. Set to 1 or higher for latency-critical applications to avoid cold starts."
  type        = number
  default     = 0
}

variable "project_id" {
  description = "The Google Cloud project ID where the Cloud Run service will be deployed. If not provided, the provider project will be used."
  type        = string
  default     = null
}

variable "request_timeout_seconds" {
  description = "The timeout for responding to a request in seconds."
  type        = number
  default     = 300
}

variable "secret_env_vars" {
  description = "A map of environment variables sourced from Secret Manager. The map key is the environment variable name, and the value is an object with `secret_name` and `secret_version` attributes."
  type = map(object({
    secret_name    = string
    secret_version = string
  }))
  default = {}
}

variable "secret_volumes" {
  description = "A map defining secrets to be mounted as files. The map key is the mount path (e.g., '/etc/secrets'), and the value is an object with a `secret_name` attribute and an `items` map. The `items` map has filenames as keys and secret versions as values. This is the most secure method for handling secrets."
  type = map(object({
    secret_name = string
    items       = map(string)
  }))
  default = {}
}

variable "service_account_create" {
  description = "If true, a dedicated service account will be created for the Cloud Run service. This is a security best practice."
  type        = bool
  default     = true
}

variable "service_account_email" {
  description = "The email of an existing service account to use for the Cloud Run service. Required if 'service_account_create' is false."
  type        = string
  default     = null
}

variable "service_name" {
  description = "The name of the Cloud Run service."
  type        = string
  default     = "example-cloud-run-service"
}

variable "startup_cpu_boost" {
  description = "If true, temporarily boosts the allocated CPU during container startup to reduce cold start latency."
  type        = bool
  default     = false
}

variable "startup_probe" {
  description = "Configuration for the startup probe, which checks if the application has started successfully. This is crucial for applications with slow startup times."
  type = object({
    initial_delay_seconds = optional(number, 0)
    timeout_seconds       = optional(number, 1)
    period_seconds        = optional(number, 10)
    failure_threshold     = optional(number, 3)
    http_get_path         = optional(string, "/")
    http_get_port         = optional(number)
  })
  default = null
}

variable "vpc_access" {
  description = "Configuration for connecting the Cloud Run service to a VPC network via a Serverless VPC Access connector."
  type = object({
    connector_id = string
    egress       = optional(string, "PRIVATE_RANGES_ONLY")
  })
  default = null
}
