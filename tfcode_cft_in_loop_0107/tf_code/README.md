# Google Cloud Run v2 Service Module

This Terraform module provides a comprehensive and secure way to deploy services to Google Cloud Run (v2). It is designed with enterprise best practices in mind, including least-privilege service accounts, secure secret management, fine-grained ingress/egress control, and detailed health checks. The module supports both simple public APIs and complex internal microservices connected to a VPC.

## Usage

### Basic Usage

Here is a basic example of how to use this module to deploy a public "hello world" service.

```hcl
module "cloud_run_service" {
  source = "./" # Replace with the actual module source

  project_id      = "your-gcp-project-id"
  location        = "us-central1"
  service_name    = "my-public-service"
  container_image = "us-docker.pkg.dev/cloudrun/container/hello"

  # Allow public access
  invokers = ["allUsers"]
}
```

### Comprehensive Example (Internal Service)

This example demonstrates a more complex setup for an internal service connected to a VPC, using a dedicated service account, secrets, and health probes.

```hcl
module "cloud_run_internal_service" {
  source = "./" # Replace with the actual module source

  project_id      = "your-gcp-project-id"
  location        = "us-central1"
  service_name    = "my-internal-app"
  container_image = "us-central1-docker.pkg.dev/your-gcp-project-id/my-repo/my-app:latest"

  # Create a dedicated service account for the service
  service_account_create = true

  # Set ingress to internal traffic only
  ingress = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  # Grant invoker permissions to another service account
  invokers = ["serviceAccount:caller-sa@your-gcp-project-id.iam.gserviceaccount.com"]

  # Connect to a VPC network
  vpc_access = {
    connector_id = "projects/your-gcp-project-id/locations/us-central1/connectors/my-vpc-connector"
    egress       = "PRIVATE_RANGES_ONLY"
  }

  # Environment variables from Secret Manager
  secret_env_vars = {
    DATABASE_PASSWORD = {
      secret_name    = "my-db-password"
      secret_version = "latest"
    }
  }

  # Mount secrets as files (most secure method)
  secret_volumes = {
    "/etc/secrets/api-key" = {
      secret_name = "api-key-secret"
      items = {
        "key.json" = "latest"
      }
    }
  }

  # Configure health checks
  liveness_probe = {
    http_get_path = "/healthz"
  }

  startup_probe = {
    http_get_path         = "/healthz"
    initial_delay_seconds = 10
    failure_threshold     = 5
  }
}
```

## Requirements

The following sections describe the requirements for using this module.

### Terraform

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 5.15.0 |

### APIs

A project with the following APIs enabled is required:

-   Cloud Run Admin API: `run.googleapis.com`
-   Identity and Access Management (IAM) API: `iam.googleapis.com`
-   Secret Manager API: `secretmanager.googleapis.com`
-   Artifact Registry API: `artifactregistry.googleapis.com`
-   Serverless VPC Access API: `vpcaccess.googleapis.com` (if using `vpc_access`)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_container_args"></a> [container\_args](#input\_container\_args) | A list of strings representing the arguments to the container command. If not specified, the container's default CMD is used. | `list(string)` | `null` | no |
| <a name="input_container_command"></a> [container\_command](#input\_container\_command) | A list of strings representing the command to run in the container. If not specified, the container's default ENTRYPOINT is used. | `list(string)` | `null` | no |
| <a name="input_container_image"></a> [container\_image](#input\_container\_image) | The full URI of the container image to deploy, hosted in Artifact Registry. GCR is deprecated and should not be used for new deployments. | `string` | `"us-docker.pkg.dev/cloudrun/container/hello"` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | The port number that the container listens on for incoming requests. | `number` | `8080` | no |
| <a name="input_cpu_idle"></a> [cpu\_idle](#input\_cpu\_idle) | If true (default), CPU is only allocated during request processing (request-based billing). If false, CPU is allocated for the entire container instance lifecycle (instance-based billing), which is required for background processing. | `bool` | `true` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | The maximum amount of CPU to allocate to the container instance, e.g., '1' for 1 vCPU. Billing is based on this allocation. | `string` | `"1"` | no |
| <a name="input_default_uri_disabled"></a> [default\_uri\_disabled](#input\_default\_uri\_disabled) | If true, disables the default '*.run.app' URL. This is a security best practice when the service is only exposed via a Load Balancer. | `bool` | `false` | no |
| <a name="input_env_vars"></a> [env\_vars](#input\_env\_vars) | A map of plaintext environment variables to set in the container, where the key is the variable name and the value is its content. | `map(string)` | `{}` | no |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Controls who can reach the service. Valid values INGRESS\_TRAFFIC\_ALL, INGRESS\_TRAFFIC\_INTERNAL\_ONLY, INGRESS\_TRAFFIC\_INTERNAL\_LOAD\_BALANCER. | `string` | `"INGRESS_TRAFFIC_ALL"` | no |
| <a name="input_invokers"></a> [invokers](#input\_invokers) | A list of IAM members who should be granted 'roles/run.invoker' permission. For example, `["allUsers", "serviceAccount:my-invoker@project.iam.gserviceaccount.com"]`. | `list(string)` | `[]` | no |
| <a name="input_liveness_probe"></a> [liveness\_probe](#input\_liveness\_probe) | Configuration for the liveness probe, which checks if the container is still responsive. If it fails, the container is restarted. It is highly recommended to configure this. | <pre>object({<br>    initial_delay_seconds = optional(number, 0)<br>    timeout_seconds       = optional(number, 1)<br>    period_seconds        = optional(number, 10)<br>    failure_threshold     = optional(number, 3)<br>    http_get_path         = optional(string, "/")<br>    http_get_port         = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | The Google Cloud region to deploy the Cloud Run service in. | `string` | `"us-central1"` | no |
| <a name="input_max_instance_count"></a> [max\_instance\_count](#input\_max\_instance\_count) | The maximum number of container instances that the service can scale up to. | `number` | `100` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | The maximum amount of memory to allocate to the container instance, e.g., '512Mi'. Billing is based on this allocation. | `string` | `"512Mi"` | no |
| <a name="input_min_instance_count"></a> [min\_instance\_count](#input\_min\_instance\_count) | The minimum number of container instances to keep running. Set to 1 or higher for latency-critical applications to avoid cold starts. | `number` | `0` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The Google Cloud project ID where the Cloud Run service will be deployed. If not provided, the provider project will be used. | `string` | `null` | no |
| <a name="input_request_timeout_seconds"></a> [request\_timeout\_seconds](#input\_request\_timeout\_seconds) | The timeout for responding to a request in seconds. | `number` | `300` | no |
| <a name="input_secret_env_vars"></a> [secret\_env\_vars](#input\_secret\_env\_vars) | A map of environment variables sourced from Secret Manager. The map key is the environment variable name, and the value is an object with `secret_name` and `secret_version` attributes. | <pre>map(object({<br>    secret_name    = string<br>    secret_version = string<br>  }))</pre> | `{}` | no |
| <a name="input_secret_volumes"></a> [secret\_volumes](#input\_secret\_volumes) | A map defining secrets to be mounted as files. The map key is the mount path (e.g., '/etc/secrets'), and the value is an object with a `secret_name` attribute and an `items` map. The `items` map has filenames as keys and secret versions as values. This is the most secure method for handling secrets. | <pre>map(object({<br>    secret_name = string<br>    items       = map(string)<br>  }))</pre> | `{}` | no |
| <a name="input_service_account_create"></a> [service\_account\_create](#input\_service\_account\_create) | If true, a dedicated service account will be created for the Cloud Run service. This is a security best practice. | `bool` | `true` | no |
| <a name="input_service_account_email"></a> [service\_account\_email](#input\_service\_account\_email) | The email of an existing service account to use for the Cloud Run service. Required if 'service\_account\_create' is false. | `string` | `null` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | The name of the Cloud Run service. | `string` | `"example-cloud-run-service"` | no |
| <a name="input_startup_cpu_boost"></a> [startup\_cpu\_boost](#input\_startup\_cpu\_boost) | If true, temporarily boosts the allocated CPU during container startup to reduce cold start latency. | `bool` | `false` | no |
| <a name="input_startup_probe"></a> [startup\_probe](#input\_startup\_probe) | Configuration for the startup probe, which checks if the application has started successfully. This is crucial for applications with slow startup times. | <pre>object({<br>    initial_delay_seconds = optional(number, 0)<br>    timeout_seconds       = optional(number, 1)<br>    period_seconds        = optional(number, 10)<br>    failure_threshold     = optional(number, 3)<br>    http_get_path         = optional(string, "/")<br>    http_get_port         = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_vpc_access"></a> [vpc\_access](#input\_vpc\_access) | Configuration for connecting the Cloud Run service to a VPC network via a Serverless VPC Access connector. | <pre>object({<br>    connector_id = string<br>    egress       = optional(string, "PRIVATE_RANGES_ONLY")<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_latest_ready_revision"></a> [latest\_ready\_revision](#output\_latest\_ready\_revision) | The name of the last revision that was successfully deployed. |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | The email address of the service account used by this Cloud Run service. |
| <a name="output_service_id"></a> [service\_id](#output\_service\_id) | The fully qualified identifier of the Cloud Run service. |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | The name of the Cloud Run service. |
| <a name="output_service_url"></a> [service\_url](#output\_service\_url) | The primary public or internal URL of the Cloud Run service. |
