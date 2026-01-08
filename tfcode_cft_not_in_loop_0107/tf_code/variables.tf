variable "annotations" {
  description = "A map of key/value annotation pairs to assign to the service."
  type        = map(string)
  default     = {}
}

variable "container_args" {
  description = "A list of arguments to the container's entrypoint."
  type        = list(string)
  default     = null
}

variable "container_command" {
  description = "The entrypoint for the container. If not specified, the container's default entrypoint is used."
  type        = list(string)
  default     = null
}

variable "container_port" {
  description = "The port number that the container listens on."
  type        = number
  default     = 8080
}

variable "container_resources" {
  description = "A map defining the desired resource limits for the container, e.g., { limits = { cpu = \"1\", memory = \"512Mi\" } }. Setting explicit limits is a best practice for cost control."
  type = object({
    limits = map(string)
  })
  default = null
}

variable "cpu_idle" {
  description = "If true, CPU is only allocated during request processing (request-based billing). If false, CPU is always allocated (instance-based billing), which is required for background activity."
  type        = bool
  default     = true
}

variable "custom_audiences" {
  description = "A list of custom audiences that can be used to authenticate with Google-issued ID tokens."
  type        = list(string)
  default     = []
}

variable "default_uri_disabled" {
  description = "When true, disables the default '*.run.app' URL for the service. This is a security best practice when the service is only exposed via a Load Balancer."
  type        = bool
  default     = false
}

variable "description" {
  description = "An optional description of the service."
  type        = string
  default     = null
}

variable "encryption_key" {
  description = "The full name of the CMEK key to use for encryption. The Cloud Run Service Agent and the project's service account must have the 'Cloud KMS CryptoKey Encrypter/Decrypter' role on this key."
  type        = string
  default     = null
}

variable "env_vars" {
  description = "A list of key-value pairs to set as environment variables."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "execution_environment" {
  description = "The execution environment for the container. Valid values are 'EXECUTION_ENVIRONMENT_GEN1' and 'EXECUTION_ENVIRONMENT_GEN2'."
  type        = string
  default     = "EXECUTION_ENVIRONMENT_GEN2"
}

variable "iam_members" {
  description = "A map of IAM roles to a list of members who should be granted the role for the service. For public access, use role 'roles/run.invoker' with member 'allUsers'."
  type        = map(list(string))
  default     = {}
}

variable "image" {
  description = "The container image to deploy. It is recommended to use an image from Artifact Registry."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "ingress" {
  description = "Controls who can reach the Cloud Run service. Valid values are INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER."
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "labels" {
  description = "A map of key/value label pairs to assign to the service."
  type        = map(string)
  default     = {}
}

variable "liveness_probe" {
  description = "Liveness probe configuration to check if the container is responsive. Failed probes will result in the container being restarted."
  type = object({
    initial_delay_seconds = optional(number)
    timeout_seconds       = optional(number, 1)
    period_seconds        = optional(number, 10)
    failure_threshold     = optional(number, 3)
    http_get = optional(object({
      path = string
      port = optional(number)
    }))
    tcp_socket = optional(object({
      port = number
    }))
    grpc = optional(object({
      port    = number
      service = optional(string)
    }))
  })
  default = null
}

variable "location" {
  description = "The Google Cloud location where the service will be deployed."
  type        = string
  default     = "us-central1"
}

variable "max_instance_count" {
  description = "The maximum number of container instances that can be started for this service. Used to control scaling and costs."
  type        = number
  default     = 100
}

variable "max_instance_request_concurrency" {
  description = "The maximum number of concurrent requests that can be sent to a single container instance. Higher values are suitable for I/O-bound workloads, lower for CPU-bound."
  type        = number
  default     = 80
}

variable "min_instance_count" {
  description = "The minimum number of container instances that must be running for this service. Set to 1 or higher to reduce cold starts for latency-sensitive applications."
  type        = number
  default     = 0
}

variable "name" {
  description = "The name of the Cloud Run service."
  type        = string
  default     = "cloud-run-service-example"
}

variable "project_id" {
  description = "The Google Cloud project ID. If null, the provider project is used."
  type        = string
  default     = null
}

variable "request_timeout_seconds" {
  description = "The maximum time in seconds that a request is allowed to run. If a request does not respond within this time, it is terminated."
  type        = number
  default     = 300
}

variable "secret_env_vars" {
  description = "A list of environment variables sourced from Secret Manager. Each object has 'name', 'secret', and 'version'."
  type = list(object({
    name    = string
    secret  = string
    version = string
  }))
  default = []
}

variable "secret_volumes" {
  description = "A map of secrets to mount as volumes, which is the most secure way to handle credentials. The map key is the logical volume name. The value is an object with 'mount_path', 'secret' name, and an 'items' map of filenames to secret versions."
  type = map(object({
    mount_path = string
    secret     = string
    items      = map(string)
  }))
  default = {}
}

variable "service_account" {
  description = "The email of the IAM service account to be used by the Cloud Run service. It is a security best practice to use a dedicated service account with the least privileges required."
  type        = string
  default     = null
}

variable "session_affinity" {
  description = "If true, enables session affinity for the service. Requests from the same client are sent to the same container instance."
  type        = bool
  default     = false
}

variable "startup_cpu_boost" {
  description = "If true, temporarily boosts the CPU allocation during container startup to reduce cold start latency."
  type        = bool
  default     = false
}

variable "startup_probe" {
  description = "Startup probe configuration to check if the container has started. Important for applications with long initialization times."
  type = object({
    initial_delay_seconds = optional(number)
    timeout_seconds       = optional(number, 1)
    period_seconds        = optional(number, 10)
    failure_threshold     = optional(number, 3)
    http_get = optional(object({
      path = string
      port = optional(number)
    }))
    tcp_socket = optional(object({
      port = number
    }))
    grpc = optional(object({
      port    = number
      service = optional(string)
    }))
  })
  default = null
}

variable "vpc_access" {
  description = "Configuration for connecting to a VPC network. 'connector' is the full ID of the VPC Access Connector. 'egress' can be 'PRIVATE_RANGES_ONLY' or 'ALL_TRAFFIC'."
  type = object({
    connector = string
    egress    = optional(string, "PRIVATE_RANGES_ONLY")
  })
  default = null
}
