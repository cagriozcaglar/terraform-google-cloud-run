# A map of user-defined annotations to apply to the service and revision.
variable "annotations" {
  description = "A map of user-defined annotations to apply to the service and revision. A common annotation is 'run.googleapis.com/cloudsql-instances' to connect to Cloud SQL."
  type        = map(string)
  default     = {}
}

# The arguments to pass to the container's entrypoint.
variable "container_args" {
  description = "Arguments to the entrypoint. The docker image's CMD is used if this is not provided."
  type        = list(string)
  default     = null
}

# The command to run when the container starts.
variable "container_command" {
  description = "Entrypoint array. Not executed within a shell. The docker image's ENTRYPOINT is used if this is not provided."
  type        = list(string)
  default     = null
}

# The port number the container listens on for incoming requests.
variable "container_port" {
  description = "The port number that the container listens on for incoming requests."
  type        = number
  default     = 8080
}

# Disables the default *.run.app URL.
variable "default_uri_disabled" {
  description = "If true, the default `*.run.app` URL is disabled. Recommended when using a custom domain or load balancer with IAP."
  type        = bool
  default     = false
}

# A map of plaintext environment variables to set in the container.
variable "env_vars" {
  description = "A map of plaintext environment variables to set in the container. For secrets, use `secret_env_vars` or `secret_volumes`."
  type        = map(string)
  default     = {}
}

# The container image to deploy.
variable "image" {
  description = "The container image to deploy, preferably from Artifact Registry (e.g., 'us-central1-docker.pkg.dev/project-id/repo/image:tag')."
  type        = string
  default     = "us-run.pkg.dev/cloudrun/container/hello"
}

# The ingress traffic configuration for the service.
variable "ingress" {
  description = "Controls who can reach the Cloud Run service. Valid values are 'INGRESS_TRAFFIC_ALL', 'INGRESS_TRAFFIC_INTERNAL_ONLY', 'INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER'."
  type        = string
  default     = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
}

# A map of user-defined labels to organize the service.
variable "labels" {
  description = "A map of user-defined labels to organize the service."
  type        = map(string)
  default     = {}
}

# Liveness probe configuration for the container.
variable "liveness_probe" {
  description = "Liveness probe configuration for the container. If the probe fails, the container is restarted. If null, no probe is configured."
  type = object({
    initial_delay_seconds = optional(number, 0)
    timeout_seconds       = optional(number, 1)
    period_seconds        = optional(number, 10)
    failure_threshold     = optional(number, 3)
    http_get_path         = optional(string, "/")
  })
  default = null
}

# The location (region) where the service will be deployed.
variable "location" {
  description = "The GCP region where the Cloud Run service will be deployed."
  type        = string
  default     = "us-central1"
}

# The maximum number of concurrent requests an instance can receive.
variable "max_instance_request_concurrency" {
  description = "The maximum number of concurrent requests an instance can receive."
  type        = number
  default     = 80
}

# The name of the Cloud Run service.
variable "name" {
  description = "The name of the Cloud Run service."
  type        = string
  default     = "cloud-run-service-example"
}

# The project ID where the service will be created.
variable "project_id" {
  description = "The GCP project ID where the Cloud Run service will be created. If not provided, the provider project will be used."
  type        = string
  default     = null
}

# Grants public, unauthenticated access to the service.
variable "public_access" {
  description = "If true, grants the 'roles/run.invoker' role to 'allUsers', making the service publicly accessible."
  type        = bool
  default     = false
}

# The CPU and memory resource limits for the container.
variable "resources" {
  description = "The CPU and memory resource limits for the container. In Cloud Run Gen2, CPU is always allocated. Set to the minimum required to control costs."
  type = object({
    cpu    = optional(string, "1")
    memory = optional(string, "512Mi")
  })
  default = {}
}

# The scaling configuration for the service.
variable "scaling" {
  description = "The scaling configuration for the service, including min/max instances."
  type = object({
    min_instance_count = optional(number, 0)
    max_instance_count = optional(number, 100)
  })
  default = {
    min_instance_count = 0
    max_instance_count = 100
  }
}

# A map of environment variables sourced from Secret Manager.
variable "secret_env_vars" {
  description = "A map of environment variables sourced from Secret Manager. The key is the env var name, the value is an object with 'secret' and 'version'."
  type = map(object({
    secret  = string
    version = string
  }))
  default = {}
}

# A map of secrets to be mounted as volumes in the container.
variable "secret_volumes" {
  description = "A map of secrets to mount as volumes. The key is the volume name. The value specifies mount path, secret name, and a map of items (filename to secret version). This is the most secure method for credentials."
  type = map(object({
    mount_path = string
    secret     = string
    items      = map(string)
  }))
  default = {}
}

# The email address of the IAM service account for the service.
variable "service_account_email" {
  description = "The email address of the dedicated IAM service account to be used by the service's revision. Enforces the principle of least privilege. If not provided, the default compute service account is used."
  type        = string
  default     = null
}

# Enables startup CPU boost to reduce cold start times.
variable "startup_cpu_boost" {
  description = "If true, the container gets a temporary CPU boost during startup, reducing cold start latency."
  type        = bool
  default     = false
}

# Startup probe configuration for the container.
variable "startup_probe" {
  description = "Startup probe configuration for the container. Delays the liveness probe until the container has started. Crucial for apps with long startup times. If null, no probe is configured."
  type = object({
    initial_delay_seconds = optional(number, 0)
    timeout_seconds       = optional(number, 1)
    period_seconds        = optional(number, 10)
    failure_threshold     = optional(number, 3)
    http_get_path         = optional(string, "/")
  })
  default = null
}

# The VPC Access Connector configuration for the service.
variable "vpc_access" {
  description = "Configuration for the VPC Access Connector, enabling the service to connect to VPC resources."
  type = object({
    connector = string
    egress    = optional(string, "PRIVATE_RANGES_ONLY")
  })
  default = null
}
