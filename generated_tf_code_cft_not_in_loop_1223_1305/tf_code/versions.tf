# The terraform block is used to configure aspects of Terraform itself.
# It includes settings for required Terraform version and provider versions.
terraform {
  # Specifies the required version of Terraform to be used.
  # This ensures that the module is used with a compatible version of Terraform.
  required_version = ">= 1.3.0"

  # Specifies the required providers and their versions.
  # This ensures that the module uses a compatible version of the Google Cloud provider.
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.14"
    }
  }
}
