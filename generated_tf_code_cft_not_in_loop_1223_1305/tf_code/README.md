# Terraform Google Cloud Run Service Module

This module creates and manages a Google Cloud Run v2 service. It provides a comprehensive set of features including custom domain mapping, VPC connector integration, secret management (via environment variables and volumes), and configurable scaling, resource allocation, and health probes.

## Usage

Below is a basic example of how to use the module:

```hcl
module "cloud_run_service" {
  source                = "./" // Or a Git repository URL
  project_id            = "your-gcp-project-id"
  name                  = "my-cloud-run-app"
  location              = "us-central1"
  image                 = "us-central1-docker.pkg.dev/your-gcp-project-id/repo/image:latest"
  service_account_email = "my-service-account@your-gcp-project-id.iam.gserviceaccount.com"

  // Allow public access
  allow_unauthenticated = true

  // Set environment variables
  env_vars = {
    "LOG_LEVEL" = "INFO"
  }

  // Set environment variables from Secret Manager
  secret_env_vars = {
    "API_KEY" = {
      secret  = "my-api-key-secret"
      version = "latest"
    }
  }

  // Configure scaling
  scaling = {
    min_instance_count             = 1 // Set to 1 to avoid cold starts
    max_instance_count             = 5
    max_instance_request_concurrency = 50
  }

  // Map a custom domain
  domain_mappings = ["app.your-domain.com"]
}

```

## Requirements

Before this module can be used on a project, you must ensure that the following APIs are enabled on the project:

-   Cloud Run API: `run.googleapis.com`
-   Secret Manager API: `secretmanager.googleapis.com` (if using secrets)
-   Serverless VPC Access API: `vpcaccess.googleapis.com` (if using VPC access)

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 5.14 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_unauthenticated"></a> [allow\_unauthenticated](#input\_allow\_unauthenticated) | If true, creates an IAM policy to allow unauthenticated public access to the service. | `bool` | `false` | no |
| <a name="input_container_args"></a> [container\_args](#input\_container\_args) | The arguments to the entrypoint. Corresponds to the 'CMD' instruction in a Dockerfile. | `list(string)` | `null` | no |
| <a name="input_container_command"></a> [container\_command](#input\_container\_command) | The entrypoint for the container. If not specified, the container's default entrypoint is used. | `list(string)` | `null` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | The port number that the container listens on for incoming requests. | `number` | `8080` | no |
| <a name="input_domain_mappings"></a> [domain\_mappings](#input\_domain\_mappings) | A list of custom domain names to map to the Cloud Run service. You must verify ownership of the domains in GCP. | `list(string)` | `[]` | no |
| <a name="input_env_vars"></a> [env\_vars](#input\_env\_vars) | A map of plain-text environment variables to set in the container. Key is the variable name, value is the variable value. | `map(string)` | `{}` | no |
| <a name="input_execution_environment"></a> [execution\_environment](#input\_execution\_environment) | The execution environment for the container. Can be 'EXECUTION\_ENVIRONMENT\_GEN1' or 'EXECUTION\_ENVIRONMENT\_GEN2'. | `string` | `"EXECUTION_ENVIRONMENT_GEN2"` | no |
| <a name="input_image"></a> [image](#input\_image) | The container image to deploy. Best practice is to use an image from Artifact Registry (e.g., 'us-central1-docker.pkg.dev/project/repo/image'). | `string` | `null` | yes |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Controls who can send requests to this service. Options are INGRESS\_TRAFFIC\_ALL, INGRESS\_TRAFFIC\_INTERNAL\_ONLY, INGRESS\_TRAFFIC\_INTERNAL\_LOAD\_BALANCER. | `string` | `"INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"` | no |
| <a name="input_liveness_probe"></a> [liveness\_probe](#input\_liveness\_probe) | Liveness probe configuration to check if the container is responsive. If the probe fails, the container is restarted. | <pre>object({<br>    initial_delay_seconds = optional(number, 0)<br>    timeout_seconds       = optional(number, 1)<br>    period_seconds        = optional(number, 10)<br>    failure_threshold     = optional(number, 3)<br>    http_get_path         = optional(string, "/")<br>  })</pre> | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | The Google Cloud region for the service. | `string` | `null` | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the Cloud Run service. | `string` | `null` | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the Google Cloud project. | `string` | `null` | yes |
| <a name="input_resources"></a> [resources](#input\_resources) | Resource allocation for the container, including CPU/memory limits, CPU idle, and startup boost settings. | <pre>object({<br>    limits            = map(string)<br>    cpu_idle          = bool<br>    startup_cpu_boost = bool<br>  })</pre> | <pre>{<br>  "cpu_idle": true,<br>  "limits": {<br>    "cpu": "1",<br>    "memory": "512Mi"<br>  },<br>  "startup_cpu_boost": false<br>}</pre> | no |
| <a name="input_scaling"></a> [scaling](#input\_scaling) | Scaling configuration for the service, including min/max instances and concurrency. | <pre>object({<br>    min_instance_count             = number<br>    max_instance_count             = number<br>    max_instance_request_concurrency = number<br>  })</pre> | <pre>{<br>  "max_instance_count": 100,<br>  "max_instance_request_concurrency": 80,<br>  "min_instance_count": 0<br>}</pre> | no |
| <a name="input_secret_env_vars"></a> [secret\_env\_vars](#input\_secret\_env\_vars) | A map of environment variables sourced from Secret Manager. The map key is the environment variable name. The value is an object with 'secret' (the secret name) and 'version'. | <pre>map(object({<br>    secret  = string<br>    version = string<br>  }))</pre> | `{}` | no |
| <a name="input_secret_volumes"></a> [secret\_volumes](#input\_secret\_volumes) | A map of volumes to create from Secret Manager secrets. The map key is the volume name. The value is an object containing the 'secret' name and a list of 'items' to mount. | <pre>map(object({<br>    secret = string<br>    items = list(object({<br>      version = string<br>      path    = string<br>      mode    = optional(number)<br>    }))<br>  }))</pre> | `{}` | no |
| <a name="input_service_account_email"></a> [service\_account\_email](#input\_service\_account\_email) | The email of the IAM Service Account to be used by the Cloud Run service. Using a dedicated, least-privilege service account is a security best practice. | `string` | `null` | no |
| <a name="input_startup_probe"></a> [startup\_probe](#input\_startup\_probe) | Startup probe configuration to check if the application has started successfully. Essential for services with slow start times. | <pre>object({<br>    initial_delay_seconds = optional(number, 0)<br>    timeout_seconds       = optional(number, 240)<br>    period_seconds        = optional(number, 10)<br>    failure_threshold     = optional(number, 1)<br>    http_get_path         = optional(string, "/")<br>  })</pre> | `null` | no |
| <a name="input_volume_mounts"></a> [volume\_mounts](#input\_volume\_mounts) | A map of volume mounts for the container. The map key must correspond to a volume name defined in 'secret\_volumes'. The value is the container mount path. | `map(string)` | `{}` | no |
| <a name="input_vpc_access"></a> [vpc\_access](#input\_vpc\_access) | Configuration for VPC Access Connector. The 'egress' setting defaults to 'PRIVATE\_RANGES\_ONLY' as a best practice. | <pre>object({<br>    connector = string<br>    egress    = string<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_domain_mapping_status"></a> [domain\_mapping\_status](#output\_domain\_mapping\_status) | A map of custom domain names to their mapping status, including required DNS records. You must configure these DNS records with your domain registrar. |
| <a name="output_id"></a> [id](#output\_id) | The fully qualified identifier of the Cloud Run service. |
| <a name="output_latest_ready_revision_id"></a> [latest\_ready\_revision\_id](#output\_latest\_ready\_revision\_id) | The name of the latest revision of the service that is ready to serve traffic. |
| <a name="output_location"></a> [location](#output\_location) | The location where the Cloud Run service is deployed. |
| <a name="output_name"></a> [name](#output\_name) | The name of the Cloud Run service. |
| <a name="output_uri"></a> [uri](#output\_uri) | The default URI of the Cloud Run service. |

## Resources

| Name | Type |
|------|------|
| [google_cloud_run_domain_mapping.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_domain_mapping) | resource |
| [google_cloud_run_v2_service.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service) | resource |
| [google_cloud_run_v2_service_iam_member.invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service_iam_member) | resource |
