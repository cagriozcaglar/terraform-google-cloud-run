# The GCP project ID where the Cloud Run service will be deployed.
variable "project_id" {
  description = "The ID of the Google Cloud project."
  type        = string
  default     = null
}

# The name of the Cloud Run service.
variable "name" {
  description = "The name of the Cloud Run service."
  type        = string
  default     = null
}

# The GCP location where the Cloud Run service will be deployed.
variable "location" {
  description = "The Google Cloud region for the service."
  type        = string
  default     = null
}

# The container image to deploy.
variable "image" {
  description = "The container image to deploy. Best practice is to use an image from Artifact Registry (e.g., 'us-central1-docker.pkg.dev/project/repo/image')."
  type        = string
  default     = null
}

# Ingress setting for the service.
variable "ingress" {
  description = "Controls who can send requests to this service. Options are INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER."
  type        = string
  default     = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
}

# A flag to allow unauthenticated access to the service.
variable "allow_unauthenticated" {
  description = "If true, creates an IAM policy to allow unauthenticated public access to the service."
  type        = bool
  default     = false
}

# The service account to be used by the Cloud Run service.
variable "service_account_email" {
  description = "The email of the IAM Service Account to be used by the Cloud Run service. Using a dedicated, least-privilege service account is a security best practice."
  type        = string
  default     = null
}

# The execution environment for the service.
variable "execution_environment" {
  description = "The execution environment for the container. Can be 'EXECUTION_ENVIRONMENT_GEN1' or 'EXECUTION_ENVIRONMENT_GEN2'."
  type        = string
  default     = "EXECUTION_ENVIRONMENT_GEN2"
}

# The port the container listens on.
variable "container_port" {
  description = "The port number that the container listens on for incoming requests."
  type        = number
  default     = 8080
}

# The command to run when the container starts.
variable "container_command" {
  description = "The entrypoint for the container. If not specified, the container's default entrypoint is used."
  type        = list(string)
  default     = null
}

# The arguments for the container's entrypoint.
variable "container_args" {
  description = "The arguments to the entrypoint. Corresponds to the 'CMD' instruction in a Dockerfile."
  type        = list(string)
  default     = null
}

# A map of plain-text environment variables.
variable "env_vars" {
  description = "A map of plain-text environment variables to set in the container. Key is the variable name, value is the variable value."
  type        = map(string)
  default     = {}
}

# A map of environment variables sourced from Secret Manager.
variable "secret_env_vars" {
  description = "A map of environment variables sourced from Secret Manager. The map key is the environment variable name. The value is an object with 'secret' (the secret name) and 'version'."
  type = map(object({
    secret  = string
    version = string
  }))
  default = {}
}

# A map of volumes to be created from Secret Manager secrets.
variable "secret_volumes" {
  description = "A map of volumes to create from Secret Manager secrets. The map key is the volume name. The value is an object containing the 'secret' name and a list of 'items' to mount."
  type = map(object({
    secret = string
    items = list(object({
      version = string
      path    = string
      mode    = optional(number)
    }))
  }))
  default = {}
}

# A map of volume mounts for the container.
variable "volume_mounts" {
  description = "A map of volume mounts for the container. The map key must correspond to a volume name defined in 'secret_volumes'. The value is the container mount path."
  type        = map(string)
  default     = {}
}

# Scaling configuration for the service.
variable "scaling" {
  description = "Scaling configuration for the service, including min/max instances and concurrency."
  type = object({
    min_instance_count             = number
    max_instance_count             = number
    max_instance_request_concurrency = number
  })
  default = {
    min_instance_count             = 0
    max_instance_count             = 100
    max_instance_request_concurrency = 80
  }
}

# Resource allocation for the container.
variable "resources" {
  description = "Resource allocation for the container, including CPU/memory limits, CPU idle, and startup boost settings."
  type = object({
    limits            = map(string)
    cpu_idle          = bool
    startup_cpu_boost = bool
  })
  default = {
    limits = {
      cpu    = "1"
      memory = "512Mi"
    }
    cpu_idle          = true
    startup_cpu_boost = false
  }
}

# VPC Access configuration.
variable "vpc_access" {
  description = "Configuration for VPC Access Connector. The 'egress' setting defaults to 'PRIVATE_RANGES_ONLY' as a best practice."
  type = object({
    connector = string
    egress    = string
  })
  default = null
  validation {
    condition     = var.vpc_access == null ? true : contains(["ALL_TRAFFIC", "PRIVATE_RANGES_ONLY"], var.vpc_access.egress)
    error_message = "The egress value must be one of 'ALL_TRAFFIC' or 'PRIVATE_RANGES_ONLY'."
  }
}

# Liveness probe configuration.
variable "liveness_probe" {
  description = "Liveness probe configuration to check if the container is responsive. If the probe fails, the container is restarted."
  type = object({
    initial_delay_seconds = optional(number, 0)
    timeout_seconds       = optional(number, 1)
    period_seconds        = optional(number, 10)
    failure_threshold     = optional(number, 3)
    http_get_path         = optional(string, "/")
  })
  default = null
}

# Startup probe configuration.
variable "startup_probe" {
  description = "Startup probe configuration to check if the application has started successfully. Essential for services with slow start times."
  type = object({
    initial_delay_seconds = optional(number, 0)
    timeout_seconds       = optional(number, 240)
    period_seconds        = optional(number, 10)
    failure_threshold     = optional(number, 1)
    http_get_path         = optional(string, "/")
  })
  default = null
}

# A list of custom domains to map to the service.
variable "domain_mappings" {
  description = "A list of custom domain names to map to the Cloud Run service. You must verify ownership of the domains in GCP."
  type        = list(string)
  default     = []
}
