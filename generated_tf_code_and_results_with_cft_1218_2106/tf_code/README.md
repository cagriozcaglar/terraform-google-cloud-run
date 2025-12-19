# Google Cloud Run v2 Service Module

This module handles the deployment of a containerized application as a Google Cloud Run v2 service. It provides a comprehensive set of configurable options, including scaling, networking, security, environment configuration, and health checks, using best practices like Gen2 execution environment and dedicated service accounts.

## Usage

Basic usage of this module is as follows:

```hcl
module "cloud_run_service" {
  source  = " " # This module's path

  project_id = "your-gcp-project-id"
  name       = "my-awesome-service"
  location   = "us-central1"
  image      = "us-docker.pkg.dev/cloudrun/container/hello"

  // Use a dedicated service account for least privilege
  service_account_email = "my-service-account@your-gcp-project-id.iam.gserviceaccount.com"

  // Example of environment variables and annotations for Cloud SQL
  env_vars = {
    DB_USER = "my-app"
  }
  annotations = {
    "run.googleapis.com/cloudsql-instances" = "your-gcp-project-id:us-central1:your-sql-instance"
  }

  // Example of mounting a secret as a volume
  secret_volumes = {
    "db-pass" = {
      mount_path = "/secrets/db"
      secret     = "my-db-password-secret"
      items = {
        "password" = "latest" // Mount the 'latest' version of the secret as a file named 'password'
      }
    }
  }
}
```

## Requirements

The following providers are required by this module:

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 5.14 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_annotations"></a> [annotations](#input\_annotations) | A map of user-defined annotations to apply to the service and revision. A common annotation is 'run.googleapis.com/cloudsql-instances' to connect to Cloud SQL. | `map(string)` | `{}` | no |
| <a name="input_container_args"></a> [container\_args](#input\_container\_args) | Arguments to the entrypoint. The docker image's CMD is used if this is not provided. | `list(string)` | `null` | no |
| <a name="input_container_command"></a> [container\_command](#input\_container\_command) | Entrypoint array. Not executed within a shell. The docker image's ENTRYPOINT is used if this is not provided. | `list(string)` | `null` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | The port number that the container listens on for incoming requests. | `number` | `8080` | no |
| <a name="input_default_uri_disabled"></a> [default\_uri\_disabled](#input\_default\_uri\_disabled) | If true, the default `*.run.app` URL is disabled. Recommended when using a custom domain or load balancer with IAP. | `bool` | `false` | no |
| <a name="input_env_vars"></a> [env\_vars](#input\_env\_vars) | A map of plaintext environment variables to set in the container. For secrets, use `secret_env_vars` or `secret_volumes`. | `map(string)` | `{}` | no |
| <a name="input_image"></a> [image](#input\_image) | The container image to deploy, preferably from Artifact Registry (e.g., 'us-central1-docker.pkg.dev/project-id/repo/image:tag'). | `string` | `"us-run.pkg.dev/cloudrun/container/hello"` | no |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Controls who can reach the Cloud Run service. Valid values are 'INGRESS\_TRAFFIC\_ALL', 'INGRESS\_TRAFFIC\_INTERNAL\_ONLY', 'INGRESS\_TRAFFIC\_INTERNAL\_LOAD\_BALANCER'. | `string` | `"INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | A map of user-defined labels to organize the service. | `map(string)` | `{}` | no |
| <a name="input_liveness_probe"></a> [liveness\_probe](#input\_liveness\_probe) | Liveness probe configuration for the container. If the probe fails, the container is restarted. If null, no probe is configured. | `object({ ... })` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | The GCP region where the Cloud Run service will be deployed. | `string` | `"us-central1"` | no |
| <a name="input_max_instance_request_concurrency"></a> [max\_instance\_request\_concurrency](#input\_max\_instance\_request\_concurrency) | The maximum number of concurrent requests an instance can receive. | `number` | `80` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Cloud Run service. | `string` | `"cloud-run-service-example"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The GCP project ID where the Cloud Run service will be created. If not provided, the provider project will be used. | `string` | `null` | no |
| <a name="input_public_access"></a> [public\_access](#input\_public\_access) | If true, grants the 'roles/run.invoker' role to 'allUsers', making the service publicly accessible. | `bool` | `false` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | The CPU and memory resource limits for the container. In Cloud Run Gen2, CPU is always allocated. Set to the minimum required to control costs. | `object({ ... })` | `{}` | no |
| <a name="input_scaling"></a> [scaling](#input\_scaling) | The scaling configuration for the service, including min/max instances. | `object({ ... })` | <pre>{<br>  "max_instance_count": 100,<br>  "min_instance_count": 0<br>}</pre> | no |
| <a name="input_secret_env_vars"></a> [secret\_env\_vars](#input\_secret\_env\_vars) | A map of environment variables sourced from Secret Manager. The key is the env var name, the value is an object with 'secret' and 'version'. | `map(object({ ... }))` | `{}` | no |
| <a name="input_secret_volumes"></a> [secret\_volumes](#input\_secret\_volumes) | A map of secrets to mount as volumes. The key is the volume name. The value specifies mount path, secret name, and a map of items (filename to secret version). This is the most secure method for credentials. | `map(object({ ... }))` | `{}` | no |
| <a name="input_service_account_email"></a> [service\_account\_email](#input\_service\_account\_email) | The email address of the dedicated IAM service account to be used by the service's revision. Enforces the principle of least privilege. If not provided, the default compute service account is used. | `string` | `null` | no |
| <a name="input_startup_cpu_boost"></a> [startup\_cpu\_boost](#input\_startup\_cpu\_boost) | If true, the container gets a temporary CPU boost during startup, reducing cold start latency. | `bool` | `false` | no |
| <a name="input_startup_probe"></a> [startup\_probe](#input\_startup\_probe) | Startup probe configuration for the container. Delays the liveness probe until the container has started. Crucial for apps with long startup times. If null, no probe is configured. | `object({ ... })` | `null` | no |
| <a name="input_vpc_access"></a> [vpc\_access](#input\_vpc\_access) | Configuration for the VPC Access Connector, enabling the service to connect to VPC resources. | `object({ ... })` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The fully qualified identifier of the Cloud Run service. |
| <a name="output_latest_ready_revision"></a> [latest\_ready\_revision](#output\_latest\_ready\_revision) | Name of the latest revision that is serving traffic. |
| <a name="output_location"></a> [location](#output\_location) | The location where the Cloud Run service was deployed. |
| <a name="output_name"></a> [name](#output\_name) | The name of the Cloud Run service. |
| <a name="output_project"></a> [project](#output\_project) | The project ID where the Cloud Run service was deployed. |
| <a name="output_uri"></a> [uri](#output\_uri) | The primary public URI of the Cloud Run service. |
