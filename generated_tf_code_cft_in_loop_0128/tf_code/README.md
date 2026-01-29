# Google Cloud Run Service Module

This module handles the deployment of a configurable Google Cloud Run v2 service. It simplifies the process by managing API enablement, service configuration, and IAM policies for public access.

## Usage

Here is a basic example of how to use the module:

```hcl
module "cloud_run_service" {
  source = "./" # Or path to the module

  project_id   = "your-gcp-project-id"
  region       = "us-central1"
  service_name = "my-awesome-service"
  image        = "us-docker.pkg.dev/cloudrun/container/hello"

  // Allow public access
  allow_unauthenticated = true

  // Customize scaling
  min_instance_count = 1
  max_instance_count = 10

  // Customize resources
  cpu_limit    = "1" // 1 vCPU
  memory_limit = "512Mi"
}
```

## Requirements

The following requirements are needed by this module:

- Terraform >= 1.3.0
- Terraform Provider for Google Cloud Platform >= 5.14

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 5.14 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_cloud_run_v2_service.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service) | resource |
| [google_cloud_run_v2_service_iam_member.public_access](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service_iam_member) | resource |
| [google_project_service.apis](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_unauthenticated"></a> [allow\_unauthenticated](#input\_allow\_unauthenticated) | If true, the service will be publicly accessible by granting the 'roles/run.invoker' role to 'allUsers'. | `bool` | `true` | no |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | The port the container listens on for incoming requests. | `number` | `8080` | no |
| <a name="input_cpu_limit"></a> [cpu\_limit](#input\_cpu\_limit) | The CPU limit in Kubernetes CPU units (e.g., '1000m' for 1 vCPU). | `string` | `"1000m"` | no |
| <a name="input_image"></a> [image](#input\_image) | The container image to deploy. This can be a publicly accessible image or an image in the same project's Artifact Registry or Container Registry. | `string` | `"gcr.io/cloudrun/hello"` | no |
| <a name="input_max_instance_count"></a> [max\_instance\_count](#input\_max\_instance\_count) | The maximum number of instances for the service. Set to 0 for unlimited, or a positive integer for a specific limit. | `number` | `100` | no |
| <a name="input_memory_limit"></a> [memory\_limit](#input\_memory\_limit) | The memory limit in Kubernetes memory units (e.g., '512Mi', '1Gi'). | `string` | `"512Mi"` | no |
| <a name="input_min_instance_count"></a> [min\_instance\_count](#input\_min\_instance\_count) | The minimum number of instances for the service. Set to 0 to allow scaling to zero. | `number` | `0` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which the Cloud Run service will be deployed. If not provided, the provider project is used. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The region where the Cloud Run service will be deployed. | `string` | `"us-central1"` | no |
| <a name="input_service_account_email"></a> [service\_account\_email](#input\_service\_account\_email) | The email of the service account to be used by the service. If not specified, the default compute service account is used. | `string` | `null` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | The name of the Cloud Run service. | `string` | `"cloud-run-service-tf"` | no |
| <a name="input_timeout_seconds"></a> [timeout\_seconds](#input\_timeout\_seconds) | The maximum request execution time in seconds before the request is timed out. | `number` | `300` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_latest_revision"></a> [latest\_revision](#output\_latest\_revision) | Name of the latest revision of the service. |
| <a name="output_service_id"></a> [service\_id](#output\_service\_id) | The fully qualified ID of the Cloud Run service. |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | The name of the Cloud Run service. |
| <a name="output_service_url"></a> [service\_url](#output\_service\_url) | The publicly-accessible URL of the Cloud Run service. |