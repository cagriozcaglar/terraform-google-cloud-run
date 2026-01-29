# The project ID to deploy the service to. If not provided, the provider's project will be used.
variable "project_id" {
  description = "The ID of the project in which the Cloud Run service will be deployed. If not provided, the provider project is used."
  type        = string
  default     = null
}

# The GCP region for the Cloud Run service.
variable "region" {
  description = "The region where the Cloud Run service will be deployed."
  type        = string
  default     = "us-central1"
}

# The name for the Cloud Run service.
variable "service_name" {
  description = "The name of the Cloud Run service."
  type        = string
  default     = "cloud-run-service-tf"
}

# The container image to deploy.
variable "image" {
  description = "The container image to deploy. This can be a publicly accessible image or an image in the same project's Artifact Registry or Container Registry."
  type        = string
  default     = "gcr.io/cloudrun/hello"
}

# A boolean to control public access.
variable "allow_unauthenticated" {
  description = "If true, the service will be publicly accessible by granting the 'roles/run.invoker' role to 'allUsers'."
  type        = bool
  default     = true
}

# The port the container listens on.
variable "container_port" {
  description = "The port the container listens on for incoming requests."
  type        = number
  default     = 8080
}

# The service account to run the service as.
variable "service_account_email" {
  description = "The email of the service account to be used by the service. If not specified, the default compute service account is used."
  type        = string
  default     = null
}

# The request timeout in seconds.
variable "timeout_seconds" {
  description = "The maximum request execution time in seconds before the request is timed out."
  type        = number
  default     = 300
}

# The minimum number of instances.
variable "min_instance_count" {
  description = "The minimum number of instances for the service. Set to 0 to allow scaling to zero."
  type        = number
  default     = 0
}

# The maximum number of instances.
variable "max_instance_count" {
  description = "The maximum number of instances for the service. Set to 0 for unlimited, or a positive integer for a specific limit."
  type        = number
  default     = 100
}

# The CPU limit for the container.
variable "cpu_limit" {
  description = "The CPU limit in Kubernetes CPU units (e.g., '1000m' for 1 vCPU)."
  type        = string
  default     = "1000m"
}

# The memory limit for the container.
variable "memory_limit" {
  description = "The memory limit in Kubernetes memory units (e.g., '512Mi', '1Gi')."
  type        = string
  default     = "512Mi"
}
