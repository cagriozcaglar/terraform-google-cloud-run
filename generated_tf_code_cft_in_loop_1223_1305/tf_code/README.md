# Terraform Google Cloud Run v2 Service Module

This module deploys a Google Cloud Run v2 service with a focus on configurability and security best practices. It simplifies the process of setting up a service by providing sensible defaults while exposing a comprehensive set of options for fine-tuning.

Key features include:
-   **Dedicated Service Account:** Automatically creates a new, dedicated IAM service account for the service to enforce the principle of least privilege.
-   **Secret Management:** Integrates seamlessly with Secret Manager to inject secrets as environment variables or mounted volumes.
-   **Networking Control:** Supports VPC Access connectors, ingress controls, and the ability to disable the default service URL.
-   **Resource & Scaling Configuration:** Provides detailed control over CPU, memory, and autoscaling parameters, including CPU boost for faster cold starts.
-   **Health Checks:** Configurable startup and liveness probes to ensure service reliability and resilience.

## Usage

### Basic Example

Here is a basic example of how to use the module to deploy a simple "hello world" service:

```hcl
module "cloud_run_service" {
  source        = "./" # Or your module source
  project_id    = "your-gcp-project-id"
  name          = "my-awesome-service"
  location      = "us-central1"
  container_image = "us-docker.pkg.dev/cloudrun/container/hello"
  allow_unauthenticated = true
}
```

### Advanced Example

This example deploys a service with a VPC connector, custom environment variables, secrets mounted as a volume, and a liveness probe.

```hcl
module "cloud_run_service_advanced" {
  source        = "./" # Or your module source
  project_id    = "your-gcp-project-id"
  name          = "my-internal-app"
  location      = "europe-west1"
  container_image = "gcr.io/your-gcp-project-id/my-app:latest"

  # Service Account
  create_service_account = true
  service_account_name   = "my-internal-app-sa"

  # Container Configuration
  env_vars = [
    {
      name  = "DATABASE_URL"
      value = "postgres://user:pass@host:port/db"
    },
    {
      name = "LOG_LEVEL"
      value = "INFO"
    }
  ]
  container_port = 8000

  # Resource Management
  resources = {
    "cpu"    = "2"
    "memory" = "1Gi"
  }
  scaling = {
    min_instance_count = 1
    max_instance_count = 10
  }
  startup_cpu_boost = true

  # Security & Networking
  ingress       = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  vpc_connector = "projects/your-gcp-project-id/locations/europe-west1/connectors/my-vpc-connector"
  vpc_egress    = "PRIVATE_RANGES_ONLY"

  # Secrets
  secret_volumes = [
    {
      mount_path     = "/etc/secrets/api-key/key.txt"
      secret_name    = "my-api-key-secret"
      secret_version = "latest"
    }
  ]

  # Health Checks
  liveness_probe = {
    http_get_path     = "/healthz"
    initial_delay_seconds = 30
    period_seconds    = 15
  }

  # Metadata
  labels = {
    "env"  = "production"
    "team" = "backend"
  }
}
```

## Requirements

The following requirements are needed by this module.

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 5.30 |

## Inputs

The following input variables are supported:

### Service Identity & Location
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | The name of the Cloud Run service. | `string` | `"cloud-run-v2-service-example"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The Google Cloud project ID where the service will be deployed. If null, the provider project is used. | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | The Google Cloud region for the Cloud Run service. | `string` | `"us-central1"` | no |

### Container Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_container_image"></a> [container\_image](#input\_container\_image) | The container image to deploy. It is recommended to use an image from Artifact Registry, as Container Registry is deprecated. | `string` | `"us-docker.pkg.dev/cloudrun/container/hello"` | no |
| <a name="input_container_command"></a> [container\_command](#input\_container\_command) | An optional list of strings specifying the command to run within the container. | `list(string)` | `[]` | no |
| <a name="input_container_args"></a> [container\_args](#input\_container\_args) | An optional list of strings specifying arguments to the container command. | `list(string)` | `[]` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | The port number that the container listens on for requests. | `number` | `8080` | no |
| <a name="input_env_vars"></a> [env\_vars](#input\_env\_vars) | A list of objects representing plaintext environment variables to set in the container. Each object should have 'name' and 'value' keys. | `list(object({ name = string, value = string }))` | `[]` | no |

### Resource Management
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_resources"></a> [resources](#input\_resources) | A map defining the CPU and memory resource limits for the container. Billing is based on allocation, so set these to the minimum required values. | `map(string)` | `{ "cpu": "1", "memory": "512Mi" }` | no |
| <a name="input_scaling"></a> [scaling](#input\_scaling) | Configuration for the scaling behavior of the service, including min/max instances and concurrency. | `object({ min_instance_count = optional(number, 0), max_instance_count = optional(number, 100), max_instance_request_concurrency = optional(number, 80) })` | `{}` | no |
| <a name="input_cpu_idle"></a> [cpu\_idle](#input\_cpu\_idle) | If true (request-based billing), CPU is only allocated during request processing. Set to false (instance-based billing) only if the service needs to perform background tasks after responding to a request. | `bool` | `true` | no |
| <a name="input_startup_cpu_boost"></a> [startup\_cpu\_boost](#input\_startup\_cpu\_boost) | If true, temporarily boosts the CPU allocation during container startup to reduce cold start latency. Recommended for latency-critical applications. | `bool` | `false` | no |

### Security & Networking
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Controls who can reach the Cloud Run service. Valid values are 'INGRESS\_TRAFFIC\_ALL', 'INGRESS\_TRAFFIC\_INTERNAL\_ONLY', 'INGRESS\_TRAFFIC\_INTERNAL\_LOAD\_BALANCER'. | `string` | `"INGRESS_TRAFFIC_ALL"` | no |
| <a name="input_vpc_connector"></a> [vpc\_connector](#input\_vpc\_connector) | The self-link or ID of the Serverless VPC Access connector to use for this service. | `string` | `null` | no |
| <a name="input_vpc_egress"></a> [vpc\_egress](#input\_vpc\_egress) | The egress setting for the VPC connector. 'PRIVATE\_RANGES\_ONLY' is the recommended default. Use 'ALL\_TRAFFIC' only when a static egress IP via Cloud NAT is a strict requirement. | `string` | `"PRIVATE_RANGES_ONLY"` | no |
| <a name="input_default_uri_disabled"></a> [default\_uri\_disabled](#input\_default\_uri\_disabled) | If true, the default `*.run.app` URL is disabled. This is a security best practice when the service is behind a Load Balancer to prevent bypassing security controls. | `bool` | `false` | no |
| <a name="input_allow_unauthenticated"></a> [allow\_unauthenticated](#input\_allow\_unauthenticated) | If set to true, grants the 'roles/run.invoker' role to 'allUsers', allowing public, unauthenticated access to the service. | `bool` | `false` | no |

### Service Account
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_service_account"></a> [create\_service\_account](#input\_create\_service\_account) | If true, a new dedicated service account is created for the service. If false, `service_account_email` must be provided. Defaults to true as a security best practice. | `bool` | `true` | no |
| <a name="input_service_account_email"></a> [service\_account\_email](#input\_service\_account\_email) | The email address of the IAM Service Account to run the service. Best practice is to use a dedicated service account with least-privilege IAM roles. This is required if `create_service_account` is false. | `string` | `null` | no |
| <a name="input_service_account_name"></a> [service\_account\_name](#input\_service\_account\_name) | The `account_id` of the service account to create, used only if `create_service_account` is true. If not provided, a name will be generated based on the service name. | `string` | `null` | no |

### Secrets Integration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_secret_env_vars"></a> [secret\_env\_vars](#input\_secret\_env\_vars) | A list of objects for secrets to be exposed as environment variables. Each object should define 'env\_var\_name', 'secret\_name', and 'secret\_version'. The service account must have the 'Secret Manager Secret Accessor' role for each secret. | `list(object({ env_var_name = string, secret_name = string, secret_version = string }))` | `[]` | no |
| <a name="input_secret_volumes"></a> [secret\_volumes](#input\_secret\_volumes) | A list of objects for secrets to be mounted as files. This is the most secure method for handling credentials. Each object must define 'mount\_path', 'secret\_name', and 'secret\_version'. The service account must have the 'Secret Manager Secret Accessor' role for each secret. | `list(object({ mount_path = string, secret_name = string, secret_version = string }))` | `[]` | no |

### Health Checks
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_startup_probe"></a> [startup\_probe](#input\_startup\_probe) | Startup probe configuration. Crucial for services with long initialization times to prevent them from being killed before they are ready. | `object({ http_get_path = optional(string), initial_delay_seconds = optional(number), timeout_seconds = optional(number), period_seconds = optional(number), failure_threshold = optional(number) })` | `null` | no |
| <a name="input_liveness_probe"></a> [liveness\_probe](#input\_liveness\_probe) | Liveness probe configuration. Essential for ensuring the service is automatically restarted if it becomes unresponsive or deadlocked. | `object({ http_get_path = optional(string), initial_delay_seconds = optional(number), timeout_seconds = optional(number), period_seconds = optional(number), failure_threshold = optional(number) })` | `null` | no |

### Metadata
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_labels"></a> [labels](#input\_labels) | A map of key-value string pairs to assign as labels to the service. | `map(string)` | `{}` | no |
| <a name="input_service_annotations"></a> [service\_annotations](#input\_service\_annotations) | A map of key-value string pairs to assign as annotations to the service. | `map(string)` | `{}` | no |
| <a name="input_template_annotations"></a> [template\_annotations](#input\_template\_annotations) | A map of key-value string pairs to assign as annotations to the revision template. | `map(string)` | `{}` | no |

## Outputs

The following outputs are exported by this module:

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The fully qualified identifier of the Cloud Run service. |
| <a name="output_latest_ready_revision"></a> [latest\_ready\_revision](#output\_latest\_ready\_revision) | The name of the latest revision of the service that is ready to serve traffic. |
| <a name="output_location"></a> [location](#output\_location) | The location of the Cloud Run service. |
| <a name="output_name"></a> [name](#output\_name) | The name of the Cloud Run service. |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | The email of the service account used by the service. This is the email of the created service account if `create_service_account` is true, otherwise it is the value of `service_account_email`. |
| <a name="output_uri"></a> [uri](#output\_uri) | The primary public URI of the Cloud Run service. |
