# Annotations to apply to the service.
variable "annotations" {
  description = "A map of key-value annotations to apply to the Cloud Run service."
  type        = map(string)
  default     = {}
}

# Container arguments override.
variable "container_args" {
  description = "An array of strings representing arguments to the container's entrypoint."
  type        = list(string)
  default     = null
}

# Container command override.
variable "container_command" {
  description = "An array of strings representing the container's entrypoint."
  type        = list(string)
  default     = null
}

# Container port.
variable "container_port" {
  description = "The port number on which the container listens for requests."
  type        = number
  default     = 8080
}

# Container resource limits.
variable "container_resources" {
  description = "A map defining the CPU and memory limits for the container. Set explicit limits to the minimum required to optimize costs."
  type = object({
    limits = map(string)
  })
  default = {
    limits = {
      cpu    = "1"
      memory = "512Mi"
    }
  }
}

# CPU allocation setting.
variable "cpu_idle" {
  description = "When true (request-based billing), CPU is only allocated during request processing. When false (instance-based billing), CPU is always allocated. Set to false for reliable background activity."
  type        = bool
  default     = true
}

# Plaintext environment variables.
variable "env_vars" {
  description = "A map of plaintext environment variables to set in the container. For sensitive data, use secret_volumes or secret_env_vars instead."
  type        = map(string)
  default     = {}
}

# Execution environment.
variable "execution_environment" {
  description = "The execution environment for the service. GEN2 provides enhanced networking and performance."
  type        = string
  default     = "EXECUTION_ENVIRONMENT_GEN2"
}

# IAM bindings for the service.
variable "iam_bindings" {
  description = "A map of IAM role bindings to apply to the service. The key is the role and the value is a list of members."
  type        = map(list(string))
  default     = {}
}

# The container image to deploy.
variable "image" {
  description = "The full URI of the container image in Artifact Registry (e.g., us-central1-docker.pkg.dev/project/repo/image:tag)."
  type        = string
}

# Ingress traffic configuration.
variable "ingress" {
  description = "Controls who can reach the Cloud Run service. Valid values are INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER."
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

# Labels to apply to the service.
variable "labels" {
  description = "A map of key-value labels to apply to the Cloud Run service."
  type        = map(string)
  default     = {}
}

# Launch stage of the service.
variable "launch_stage" {
  description = "The launch stage of the service. Valid values are GA, BETA, ALPHA."
  type        = string
  default     = "GA"
}

# Liveness probe configuration.
variable "liveness_probe" {
  description = "Configuration for the liveness probe. Ensures that unresponsive or deadlocked containers are automatically restarted to maintain service health."
  type = object({
    initial_delay_seconds = optional(number)
    timeout_seconds       = optional(number, 1)
    failure_threshold     = optional(number, 3)
    period_seconds        = optional(number, 10)
    http_get = optional(object({
      path = optional(string, "/")
    }), {})
  })
  default = null
}

# The GCP location for the Cloud Run service.
variable "location" {
  description = "The GCP region where the Cloud Run service will be deployed."
  type        = string
}

# Maximum number of instances.
variable "max_instance_count" {
  description = "The maximum number of container instances that can be scaled up."
  type        = number
  default     = 100
}

# Request concurrency per instance.
variable "max_instance_request_concurrency" {
  description = "The maximum number of concurrent requests an instance can receive. Tune higher for I/O-bound workloads and lower for CPU-bound workloads."
  type        = number
  default     = 80
}

# Minimum number of instances.
variable "min_instance_count" {
  description = "The minimum number of container instances to keep active. Set to 1 or higher to reduce cold starts for latency-sensitive applications."
  type        = number
  default     = 0
}

# The name of the Cloud Run service.
variable "name" {
  description = "The name of the Cloud Run service."
  type        = string
}

# The project ID where the Cloud Run service will be deployed.
variable "project_id" {
  description = "The GCP project ID to deploy the service to."
  type        = string
}

# Secret-backed environment variables.
variable "secret_env_vars" {
  description = "A map of environment variables sourced from Secret Manager. Each key is the environment variable name, and the value specifies the secret name and version."
  type = map(object({
    secret  = string
    version = string
  }))
  default = {}
}

# Secret-backed volumes.
variable "secret_volumes" {
  description = "A map of volumes to mount from Secret Manager. Using volume mounts for secrets is more secure than environment variables. The key is the volume name, and the value specifies the secret, mount path, and file mappings."
  type = map(object({
    secret     = string
    mount_path = string
    items      = map(string)
  }))
  default = {}
}

# The service account email for the service identity.
variable "service_account_email" {
  description = "The email of the dedicated Service Account to run the service. This enforces the principle of least privilege."
  type        = string
  default     = null
}

# Startup CPU boost.
variable "startup_cpu_boost" {
  description = "When true, temporarily boosts CPU allocation during instance startup to reduce cold start latency."
  type        = bool
  default     = false
}

# Startup probe configuration.
variable "startup_probe" {
  description = "Configuration for the startup probe. Crucial for applications with slow start times (e.g., ML models) to avoid premature termination."
  type = object({
    initial_delay_seconds = optional(number)
    timeout_seconds       = optional(number, 1)
    failure_threshold     = optional(number, 3)
    period_seconds        = optional(number, 10)
    http_get = optional(object({
      path = optional(string, "/")
    }), {})
  })
  default = null
}

# Annotations for the revision template.
variable "template_annotations" {
  description = "A map of key-value annotations to apply to the service's revision template."
  type        = map(string)
  default     = {}
}

# Labels for the revision template.
variable "template_labels" {
  description = "A map of key-value labels to apply to the service's revision template."
  type        = map(string)
  default     = {}
}

# Request timeout in seconds.
variable "timeout_seconds" {
  description = "The maximum time in seconds allowed for a request to complete."
  type        = number
  default     = 300
}

# VPC Access connector ID.
variable "vpc_connector" {
  description = "The full resource ID of the Serverless VPC Access connector to connect the service to a VPC."
  type        = string
  default     = null
}

# VPC egress configuration.
variable "vpc_egress" {
  description = "The VPC egress setting. Defaults to PRIVATE_RANGES_ONLY for optimal cost and performance. Use ALL_TRAFFIC only when a static egress IP via Cloud NAT is a strict requirement."
  type        = string
  default     = "PRIVATE_RANGES_ONLY"
}
