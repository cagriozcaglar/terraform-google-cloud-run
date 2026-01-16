# Google Cloud Run Service Module

This Terraform module deploys a Google Cloud Run V2 service, designed with security and operational best practices in mind. It provides a comprehensive set of configurable options, including networking, scaling, secret management, health checks, and IAM permissions.

The module simplifies the process of launching containerized applications on Google Cloud's serverless platform, allowing you to focus on your code while adhering to recommended configurations for security, cost-optimization, and reliability.

## Usage

Here is a basic example of how to use this module to deploy a private Cloud Run service with a dedicated service account.

```hcl
module "cloud_run_service" {
  source = "./" # Or a git repository reference

  project_id = "your-gcp-project-id"
  location   = "us-central1"
  name       = "my-secure-app"
  image      = "us-central1-docker.pkg.dev/cloudrun/container/hello:latest"

  # Best practice: Use a dedicated service account
  service_account_email = "run-sa@your-gcp-project-id.iam.gserviceaccount.com"

  # Best practice: Restrict ingress to internal traffic and load balancers
  ingress              = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  default_uri_disabled = true

  # Inject secrets securely as environment variables
  secret_env_vars = [
    {
      name    = "API_KEY"
      secret  = "my-api-key-secret"
      version = "latest"
    }
  ]

  # Grant invoker permissions to a specific service account
  iam_members = {
    "roles/run.invoker" = ["serviceAccount:invoker-sa@your-gcp-project-id.iam.gserviceaccount.com"]
  }
}
```

## Requirements

### Terraform Versions

This module has been tested and is compatible with Terraform `1.3` and newer.

### Terraform Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](https://registry.terraform.io/providers/hashicorp/google) | ~> 5.0 |

### Google Cloud APIs

To use this module, you must enable the following APIs on your project:

*   **Cloud Run Admin API:** `run.googleapis.com`
*   **IAM API:** `iam.googleapis.com`
*   **Secret Manager API:** `secretmanager.googleapis.com` (if using `secret_env_vars` or `secret_volumes`)
*   **Serverless VPC Access API:** `vpcaccess.googleapis.com` (if using `vpc_access`)

## Resources

| Name | Type |
|------|------|
| [google_cloud_run_v2_service.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service) | resource |
| [google_cloud_run_v2_service_iam_member.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | The name of the Cloud Run service. | `string` | `"cloud-run-service"` | no |
| <a name="input_image"></a> [image](#input\_image) | The container image to deploy. It is a best practice to use an image from Artifact Registry (e.g., 'us-central1-docker.pkg.dev/my-project/my-repo/my-image:tag') as Container Registry is deprecated. | `string` | `"us-run.pkg.dev/cloudrun/container/hello"` | no |
| <a name="input_location"></a> [location](#input\_location) | The Google Cloud region to deploy the Cloud Run service in. | `string` | `"us-central1"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The Google Cloud project ID to deploy the Cloud Run service in. If not specified, the provider's project will be used. | `string` | `null` | no |
| <a name="input_service_account_email"></a> [service\_account\_email](#input\_service\_account\_email) | The email of the dedicated IAM Service Account to run the service. This enforces the principle of least privilege. If not specified, the default compute service account is used. | `string` | `null` | no |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Controls who can reach the service. For services behind a Load Balancer, use 'INGRESS\_TRAFFIC\_INTERNAL\_LOAD\_BALANCER'. For internal-only services, use 'INGRESS\_TRAFFIC\_INTERNAL\_ONLY'. Use 'INGRESS\_TRAFFIC\_ALL' for public services. | `string` | `"INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"` | no |
| <a name="input_default_uri_disabled"></a> [default\_uri\_disabled](#input\_default\_uri\_disabled) | When true, disables the default '*.run.app' URL. This is a security best practice when the service is only accessed through a Load Balancer or custom domain, preventing users from bypassing security controls. | `bool` | `true` | no |
| <a name="input_min_instance_count"></a> [min\_instance\_count](#input\_min\_instance\_count) | The minimum number of container instances to keep running. Set to 1 or higher for latency-critical applications to reduce cold starts. | `number` | `0` | no |
| <a name="input_max_instance_count"></a> [max\_instance\_count](#input\_max\_instance\_count) | The maximum number of container instances that can be started. This is a key cost-control setting. | `number` | `100` | no |
| <a name="input_max_instance_request_concurrency"></a> [max\_instance\_request\_concurrency](#input\_max\_instance\_request\_concurrency) | The maximum number of concurrent requests that a single container instance can receive. Tune based on workload: high for I/O-bound, lower for CPU-bound. | `number` | `80` | no |
| <a name="input_cpu_idle"></a> [cpu\_idle](#input\_cpu\_idle) | Controls CPU allocation and billing. 'true' (Request-based billing) throttles CPU when no requests are processing and is cost-effective for APIs. 'false' (Instance-based billing) keeps CPU always allocated and is required for reliable background processing. | `bool` | `true` | no |
| <a name="input_startup_cpu_boost"></a> [startup\_cpu\_boost](#input\_startup\_cpu\_boost) | When true, temporarily doubles the allocated CPU during container startup to reduce cold start latency. | `bool` | `true` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | The port that the container listens on for incoming requests. | `number` | `8080` | no |
| <a name="input_container_command"></a> [container\_command](#input\_container\_command) | The command to run when the container starts. If not specified, the container's default entrypoint is used. | `list(string)` | `null` | no |
| <a name="input_container_args"></a> [container\_args](#input\_container\_args) | The arguments to pass to the container's command. | `list(string)` | `null` | no |
| <a name="input_container_resources_limits"></a> [container\_resources\_limits](#input\_container\_resources\_limits) | A map of resource limits for the container. Set explicit limits to the minimum required size to optimize costs. Billing is based on allocation. | `map(string)` | <pre>{<br>  "cpu": "1",<br>  "memory": "512Mi"<br>}</pre> | no |
| <a name="input_env_vars"></a> [env\_vars](#input\_env\_vars) | A list of plaintext environment variables to set in the container. | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| <a name="input_secret_env_vars"></a> [secret\_env\_vars](#input\_secret\_env\_vars) | A list of environment variables sourced from Secret Manager. Each object specifies the environment variable name, the secret name (ID), and the secret version. | <pre>list(object({<br>    name    = string<br>    secret  = string<br>    version = string<br>  }))</pre> | `[]` | no |
| <a name="input_secret_volumes"></a> [secret\_volumes](#input\_secret\_volumes) | A list of secrets to mount as volumes (files) in the container. This is a secure method for injecting credentials or configuration files. Each object specifies the volume name, mount path, secret name (ID), version, and the filename. | <pre>list(object({<br>    name       = string<br>    mount_path = string<br>    secret     = string<br>    version    = string<br>    path       = optional(string)<br>  }))</pre> | `[]` | no |
| <a name="input_vpc_access"></a> [vpc\_access](#input\_vpc\_access) | Configuration for VPC Access Connector. The 'egress' setting defaults to 'PRIVATE\_RANGES\_ONLY', which is optimal for accessing private resources like Cloud SQL without routing all public traffic through the VPC and requiring a NAT gateway. | <pre>object({<br>    connector = string<br>    egress    = optional(string, "PRIVATE_RANGES_ONLY")<br>  })</pre> | `null` | no |
| <a name="input_startup_probe"></a> [startup\_probe](#input\_startup\_probe) | Health check to determine if the container has started successfully. Crucial for applications with slow startup times to avoid being killed prematurely. Set 'initial\_delay\_seconds' to allow sufficient time for initialization. | <pre>object({<br>    initial_delay_seconds = optional(number, 0)<br>    timeout_seconds       = optional(number, 1)<br>    period_seconds        = optional(number, 10)<br>    failure_threshold     = optional(number, 3)<br>    http_get_path         = optional(string)<br>    tcp_socket_port       = optional(number)<br>  })</pre> | `{}` | no |
| <a name="input_liveness_probe"></a> [liveness\_probe](#input\_liveness\_probe) | Health check to determine if the container is still responsive. If this probe fails, Cloud Run will restart the container instance. | <pre>object({<br>    initial_delay_seconds = optional(number, 0)<br>    timeout_seconds       = optional(number, 1)<br>    period_seconds        = optional(number, 10)<br>    failure_threshold     = optional(number, 3)<br>    http_get_path         = optional(string)<br>    tcp_socket_port       = optional(number)<br>  })</pre> | `{}` | no |
| <a name="input_iam_members"></a> [iam\_members](#input\_iam\_members) | A map of IAM roles to a list of members to grant access to the service. Example to make public: `{"roles/run.invoker" = ["allUsers"]}`. Example for a specific service account: `{"roles/run.invoker" = ["serviceAccount:my-invoker@my-project.iam.gserviceaccount.com"]}`. | `map(list(string))` | `{}` | no |

## Outputs

| Name | Description | Type |
|------|-------------|------|
| <a name="output_service_id"></a> [service\_id](#output\_service\_id) | The fully qualified identifier of the Cloud Run service. | `string` |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | The name of the deployed Cloud Run service. | `string` |
| <a name="output_service_uri"></a> [service\_uri](#output\_service\_uri) | The default URI of the Cloud Run service. | `string` |
| <a name="output_latest_ready_revision"></a> [latest\_ready\_revision](#output\_latest\_ready\_revision) | The name of the latest revision that is ready to serve traffic. | `string` |
| <a name="output_service"></a> [service](#output\_service) | The full Cloud Run v2 Service resource object. | `object` |
