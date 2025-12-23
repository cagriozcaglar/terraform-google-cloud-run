# Cloud Run v2 Service

This module provisions a Google Cloud Run v2 service with a focus on comprehensive and secure configuration. It allows for detailed management of container settings, scaling, networking (including VPC integration), health probes, environment variables, secret management, and IAM bindings.

## Usage

Here is a basic example of how to use this module:

```hcl
module "cloud_run_service" {
  source                = "..." # Replace with module source
  project_id            = "your-gcp-project-id"
  name                  = "my-app-service"
  location              = "us-central1"
  image                 = "us-docker.pkg.dev/cloudrun/container/hello"
  service_account_email = "my-identity@your-gcp-project-id.iam.gserviceaccount.com"

  # Expose the service publicly
  iam_bindings = {
    "roles/run.invoker" = [
      "allUsers",
    ]
  }

  # Set environment variables
  env_vars = {
    "DATABASE_URL" = "..."
  }

  # Attach secrets as environment variables
  secret_env_vars = {
    "API_KEY" = {
      secret  = "my-api-key-secret"
      version = "latest"
    }
  }

  labels = {
    "env" = "production"
  }
}
```

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 5.12.0 |

## Resources

| Name | Type |
|------|------|
| [google_cloud_run_v2_service.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service) | resource |
| [google_cloud_run_v2_service_iam_member.iam](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_annotations"></a> [annotations](#input\_annotations) | A map of key-value annotations to apply to the Cloud Run service. | `map(string)` | `{}` | no |
| <a name="input_container_args"></a> [container\_args](#input\_container\_args) | An array of strings representing arguments to the container's entrypoint. | `list(string)` | `null` | no |
| <a name="input_container_command"></a> [container\_command](#input\_container\_command) | An array of strings representing the container's entrypoint. | `list(string)` | `null` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | The port number on which the container listens for requests. | `number` | `8080` | no |
| <a name="input_container_resources"></a> [container\_resources](#input\_container\_resources) | A map defining the CPU and memory limits for the container. Set explicit limits to the minimum required to optimize costs. | <pre>object({<br>    limits = map(string)<br>  })</pre> | <pre>{<br>  "limits": {<br>    "cpu": "1",<br>    "memory": "512Mi"<br>  }<br>}</pre> | no |
| <a name="input_cpu_idle"></a> [cpu\_idle](#input\_cpu\_idle) | When true (request-based billing), CPU is only allocated during request processing. When false (instance-based billing), CPU is always allocated. Set to false for reliable background activity. | `bool` | `true` | no |
| <a name="input_env_vars"></a> [env\_vars](#input\_env\_vars) | A map of plaintext environment variables to set in the container. For sensitive data, use secret\_volumes or secret\_env\_vars instead. | `map(string)` | `{}` | no |
| <a name="input_execution_environment"></a> [execution\_environment](#input\_execution\_environment) | The execution environment for the service. GEN2 provides enhanced networking and performance. | `string` | `"EXECUTION_ENVIRONMENT_GEN2"` | no |
| <a name="input_iam_bindings"></a> [iam\_bindings](#input\_iam\_bindings) | A map of IAM role bindings to apply to the service. The key is the role and the value is a list of members. | `map(list(string))` | `{}` | no |
| <a name="input_image"></a> [image](#input\_image) | The full URI of the container image in Artifact Registry (e.g., us-central1-docker.pkg.dev/project/repo/image:tag). | `string` | n/a | yes |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Controls who can reach the Cloud Run service. Valid values are INGRESS\_TRAFFIC\_ALL, INGRESS\_TRAFFIC\_INTERNAL\_ONLY, INGRESS\_TRAFFIC\_INTERNAL\_LOAD\_BALANCER. | `string` | `"INGRESS_TRAFFIC_ALL"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | A map of key-value labels to apply to the Cloud Run service. | `map(string)` | `{}` | no |
| <a name="input_launch_stage"></a> [launch\_stage](#input\_launch\_stage) | The launch stage of the service. Valid values are GA, BETA, ALPHA. | `string` | `"GA"` | no |
| <a name="input_liveness_probe"></a> [liveness\_probe](#input\_liveness\_probe) | Configuration for the liveness probe. Ensures that unresponsive or deadlocked containers are automatically restarted to maintain service health. | <pre>object({<br>    initial_delay_seconds = optional(number)<br>    timeout_seconds       = optional(number, 1)<br>    failure_threshold     = optional(number, 3)<br>    period_seconds        = optional(number, 10)<br>    http_get = optional(object({<br>      path = optional(string, "/")<br>    }), {})<br>  })</pre> | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | The GCP region where the Cloud Run service will be deployed. | `string` | n/a | yes |
| <a name="input_max_instance_count"></a> [max\_instance\_count](#input\_max\_instance\_count) | The maximum number of container instances that can be scaled up. | `number` | `100` | no |
| <a name="input_max_instance_request_concurrency"></a> [max\_instance\_request\_concurrency](#input\_max\_instance\_request\_concurrency) | The maximum number of concurrent requests an instance can receive. Tune higher for I/O-bound workloads and lower for CPU-bound workloads. | `number` | `80` | no |
| <a name="input_min_instance_count"></a> [min\_instance\_count](#input\_min\_instance\_count) | The minimum number of container instances to keep active. Set to 1 or higher to reduce cold starts for latency-sensitive applications. | `number` | `0` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Cloud Run service. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The GCP project ID to deploy the service to. | `string` | n/a | yes |
| <a name="input_secret_env_vars"></a> [secret\_env\_vars](#input\_secret\_env\_vars) | A map of environment variables sourced from Secret Manager. Each key is the environment variable name, and the value specifies the secret name and version. | <pre>map(object({<br>    secret  = string<br>    version = string<br>  }))</pre> | `{}` | no |
| <a name="input_secret_volumes"></a> [secret\_volumes](#input\_secret\_volumes) | A map of volumes to mount from Secret Manager. Using volume mounts for secrets is more secure than environment variables. The key is the volume name, and the value specifies the secret, mount path, and file mappings. | <pre>map(object({<br>    secret     = string<br>    mount_path = string<br>    items      = map(string)<br>  }))</pre> | `{}` | no |
| <a name="input_service_account_email"></a> [service\_account\_email](#input\_service\_account\_email) | The email of the dedicated Service Account to run the service. This enforces the principle of least privilege. | `string` | `null` | no |
| <a name="input_startup_cpu_boost"></a> [startup\_cpu\_boost](#input\_startup\_cpu\_boost) | When true, temporarily boosts CPU allocation during instance startup to reduce cold start latency. | `bool` | `false` | no |
| <a name="input_startup_probe"></a> [startup\_probe](#input\_startup\_probe) | Configuration for the startup probe. Crucial for applications with slow start times (e.g., ML models) to avoid premature termination. | <pre>object({<br>    initial_delay_seconds = optional(number)<br>    timeout_seconds       = optional(number, 1)<br>    failure_threshold     = optional(number, 3)<br>    period_seconds        = optional(number, 10)<br>    http_get = optional(object({<br>      path = optional(string, "/")<br>    }), {})<br>  })</pre> | `null` | no |
| <a name="input_template_annotations"></a> [template\_annotations](#input\_template\_annotations) | A map of key-value annotations to apply to the service's revision template. | `map(string)` | `{}` | no |
| <a name="input_template_labels"></a> [template\_labels](#input\_template\_labels) | A map of key-value labels to apply to the service's revision template. | `map(string)` | `{}` | no |
| <a name="input_timeout_seconds"></a> [timeout\_seconds](#input\_timeout\_seconds) | The maximum time in seconds allowed for a request to complete. | `number` | `300` | no |
| <a name="input_vpc_connector"></a> [vpc\_connector](#input\_vpc\_connector) | The full resource ID of the Serverless VPC Access connector to connect the service to a VPC. | `string` | `null` | no |
| <a name="input_vpc_egress"></a> [vpc\_egress](#input\_vpc\_egress) | The VPC egress setting. Defaults to PRIVATE\_RANGES\_ONLY for optimal cost and performance. Use ALL\_TRAFFIC only when a static egress IP via Cloud NAT is a strict requirement. | `string` | `"PRIVATE_RANGES_ONLY"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The fully qualified identifier of the Cloud Run service. |
| <a name="output_latest_revision"></a> [latest\_revision](#output\_latest\_revision) | The name of the latest ready revision of the service. |
| <a name="output_location"></a> [location](#output\_location) | The location of the Cloud Run service. |
| <a name="output_name"></a> [name](#output\_name) | The name of the Cloud Run service. |
| <a name="output_uri"></a> [uri](#output\_uri) | The primary URI of the Cloud Run service. |
