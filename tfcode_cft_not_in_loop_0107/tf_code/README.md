# Google Cloud Run v2 Service Module

This Terraform module provides a standardized and secure way to deploy services on Google Cloud Run (v2). It encapsulates best practices for configuration, including IAM, networking, scaling, health checks, and secrets management.

This module creates the following Google Cloud resources:
- `google_cloud_run_v2_service`: The core Cloud Run service.
- `google_cloud_run_v2_service_iam_member`: Manages IAM memberships for the service, allowing fine-grained access control.

## Usage

Here is a basic example of how to use this module to deploy a simple "hello world" Cloud Run service.

```hcl
module "cloud_run_service" {
  source  = "./path/to/this/module"

  project_id = "your-gcp-project-id"
  name       = "my-awesome-service"
  location   = "us-central1"
  image      = "us-docker.pkg.dev/cloudrun/container/hello"

  iam_members = {
    "roles/run.invoker" = ["allUsers"]
  }

  env_vars = [
    {
      name  = "ENVIRONMENT"
      value = "production"
    }
  ]
}
```

For a more advanced example demonstrating VPC integration and secrets:

```hcl
module "secure_cloud_run_service" {
  source  = "./path/to/this/module"

  project_id      = "your-gcp-project-id"
  name            = "my-internal-api"
  location        = "europe-west1"
  image           = "gcr.io/your-gcp-project-id/internal-api:latest"
  service_account = "my-service-sa@your-gcp-project-id.iam.gserviceaccount.com"
  ingress         = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  vpc_access = {
    connector = "projects/your-gcp-project-id/locations/europe-west1/connectors/my-vpc-connector"
    egress    = "PRIVATE_RANGES_ONLY"
  }

  secret_env_vars = [
    {
      name    = "DATABASE_PASSWORD"
      secret  = "db-password-secret"
      version = "latest"
    }
  ]

  secret_volumes = {
    "gcp-creds" = {
      mount_path = "/etc/gcp"
      secret     = "gcp-sa-key-secret"
      items = {
        "credentials.json" = "1"
      }
    }
  }

  container_resources = {
    limits = {
      cpu    = "1"
      memory = "512Mi"
    }
  }
}
```

## Requirements

### Terraform Versions

This module has been tested and is compatible with Terraform `1.3` and newer.

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 5.14 |

### APIs

The following APIs must be enabled on the host project:

- Cloud Run API: `run.googleapis.com`
- Identity and Access Management (IAM) API: `iam.googleapis.com`
- Secret Manager API: `secretmanager.googleapis.com` (if using secrets)
- Serverless VPC Access API: `vpcaccess.googleapis.com` (if using a VPC connector)
- Cloud KMS API: `cloudkms.googleapis.com` (if using a CMEK key)

### Roles

The service account or user running Terraform must have the following roles on the project:

- `roles/run.admin`: To create and manage Cloud Run services.
- `roles/iam.serviceAccountUser`: To act as the Cloud Run service account if one is specified.

The Cloud Run Service Agent (`service-<project-number>@serverless-robot-prod.iam.gserviceaccount.com`) requires the following roles:
- `roles/secretmanager.secretAccessor`: If mounting secrets or using secret environment variables.
- `roles/cloudkms.cryptoKeyEncrypterDecrypter`: If using a Customer-Managed Encryption Key (CMEK).

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_annotations"></a> [annotations](#input\_annotations) | A map of key/value annotation pairs to assign to the service. | `map(string)` | `{}` | no |
| <a name="input_container_args"></a> [container\_args](#input\_container\_args) | A list of arguments to the container's entrypoint. | `list(string)` | `null` | no |
| <a name="input_container_command"></a> [container\_command](#input\_container\_command) | The entrypoint for the container. If not specified, the container's default entrypoint is used. | `list(string)` | `null` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | The port number that the container listens on. | `number` | `8080` | no |
| <a name="input_container_resources"></a> [container\_resources](#input\_container\_resources) | A map defining the desired resource limits for the container, e.g., { limits = { cpu = "1", memory = "512Mi" } }. Setting explicit limits is a best practice for cost control. | `object({ limits = map(string) })` | `null` | no |
| <a name="input_cpu_idle"></a> [cpu\_idle](#input\_cpu\_idle) | If true, CPU is only allocated during request processing (request-based billing). If false, CPU is always allocated (instance-based billing), which is required for background activity. | `bool` | `true` | no |
| <a name="input_custom_audiences"></a> [custom\_audiences](#input\_custom\_audiences) | A list of custom audiences that can be used to authenticate with Google-issued ID tokens. | `list(string)` | `[]` | no |
| <a name="input_default_uri_disabled"></a> [default\_uri\_disabled](#input\_default\_uri\_disabled) | When true, disables the default '*.run.app' URL for the service. This is a security best practice when the service is only exposed via a Load Balancer. | `bool` | `false` | no |
| <a name="input_description"></a> [description](#input\_description) | An optional description of the service. | `string` | `null` | no |
| <a name="input_encryption_key"></a> [encryption\_key](#input\_encryption\_key) | The full name of the CMEK key to use for encryption. The Cloud Run Service Agent and the project's service account must have the 'Cloud KMS CryptoKey Encrypter/Decrypter' role on this key. | `string` | `null` | no |
| <a name="input_env_vars"></a> [env\_vars](#input\_env\_vars) | A list of key-value pairs to set as environment variables. | `list(object({ name = string, value = string }))` | `[]` | no |
| <a name="input_execution_environment"></a> [execution\_environment](#input\_execution\_environment) | The execution environment for the container. Valid values are 'EXECUTION\_ENVIRONMENT\_GEN1' and 'EXECUTION\_ENVIRONMENT\_GEN2'. | `string` | `"EXECUTION_ENVIRONMENT_GEN2"` | no |
| <a name="input_iam_members"></a> [iam\_members](#input\_iam\_members) | A map of IAM roles to a list of members who should be granted the role for the service. For public access, use role 'roles/run.invoker' with member 'allUsers'. | `map(list(string))` | `{}` | no |
| <a name="input_image"></a> [image](#input\_image) | The container image to deploy. It is recommended to use an image from Artifact Registry. | `string` | `"us-docker.pkg.dev/cloudrun/container/hello"` | no |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Controls who can reach the Cloud Run service. Valid values are INGRESS\_TRAFFIC\_ALL, INGRESS\_TRAFFIC\_INTERNAL\_ONLY, INGRESS\_TRAFFIC\_INTERNAL\_LOAD\_BALANCER. | `string` | `"INGRESS_TRAFFIC_ALL"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | A map of key/value label pairs to assign to the service. | `map(string)` | `{}` | no |
| <a name="input_liveness_probe"></a> [liveness\_probe](#input\_liveness\_probe) | Liveness probe configuration to check if the container is responsive. Failed probes will result in the container being restarted. | `object(...)` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | The Google Cloud location where the service will be deployed. | `string` | `"us-central1"` | no |
| <a name="input_max_instance_count"></a> [max\_instance\_count](#input\_max\_instance\_count) | The maximum number of container instances that can be started for this service. Used to control scaling and costs. | `number` | `100` | no |
| <a name="input_max_instance_request_concurrency"></a> [max\_instance\_request\_concurrency](#input\_max\_instance\_request\_concurrency) | The maximum number of concurrent requests that can be sent to a single container instance. Higher values are suitable for I/O-bound workloads, lower for CPU-bound. | `number` | `80` | no |
| <a name="input_min_instance_count"></a> [min\_instance\_count](#input\_min\_instance\_count) | The minimum number of container instances that must be running for this service. Set to 1 or higher to reduce cold starts for latency-sensitive applications. | `number` | `0` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Cloud Run service. | `string` | `"cloud-run-service-example"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The Google Cloud project ID. If null, the provider project is used. | `string` | `null` | no |
| <a name="input_request_timeout_seconds"></a> [request\_timeout\_seconds](#input\_request\_timeout\_seconds) | The maximum time in seconds that a request is allowed to run. If a request does not respond within this time, it is terminated. | `number` | `300` | no |
| <a name="input_secret_env_vars"></a> [secret\_env\_vars](#input\_secret\_env\_vars) | A list of environment variables sourced from Secret Manager. Each object has 'name', 'secret', and 'version'. | `list(object({ name = string, secret = string, version = string }))` | `[]` | no |
| <a name="input_secret_volumes"></a> [secret\_volumes](#input\_secret\_volumes) | A map of secrets to mount as volumes, which is the most secure way to handle credentials. The map key is the logical volume name. The value is an object with 'mount\_path', 'secret' name, and an 'items' map of filenames to secret versions. | `map(object({ mount_path = string, secret = string, items = map(string) }))` | `{}` | no |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | The email of the IAM service account to be used by the Cloud Run service. It is a security best practice to use a dedicated service account with the least privileges required. | `string` | `null` | no |
| <a name="input_session_affinity"></a> [session\_affinity](#input\_session\_affinity) | If true, enables session affinity for the service. Requests from the same client are sent to the same container instance. | `bool` | `false` | no |
| <a name="input_startup_cpu_boost"></a> [startup\_cpu\_boost](#input\_startup\_cpu\_boost) | If true, temporarily boosts the CPU allocation during container startup to reduce cold start latency. | `bool` | `false` | no |
| <a name="input_startup_probe"></a> [startup\_probe](#input\_startup\_probe) | Startup probe configuration to check if the container has started. Important for applications with long initialization times. | `object(...)` | `null` | no |
| <a name="input_vpc_access"></a> [vpc\_access](#input\_vpc\_access) | Configuration for connecting to a VPC network. 'connector' is the full ID of the VPC Access Connector. 'egress' can be 'PRIVATE\_RANGES\_ONLY' or 'ALL\_TRAFFIC'. | `object({ connector = string, egress = optional(string, "PRIVATE_RANGES_ONLY") })` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_latest_ready_revision"></a> [latest\_ready\_revision](#output\_latest\_ready\_revision) | The name of the latest revision of the service that is ready to serve traffic. |
| <a name="output_service_id"></a> [service\_id](#output\_service\_id) | The fully qualified ID of the Cloud Run service. |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | The name of the Cloud Run service. |
| <a name="output_uri"></a> [uri](#output\_uri) | The public URI of the Cloud Run service. |
