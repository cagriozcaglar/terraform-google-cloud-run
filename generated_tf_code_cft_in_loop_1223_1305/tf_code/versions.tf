# The versions.tf file is used to specify the required Terraform version and provider versions.
terraform {
  # Specifies the required version of Terraform. This module is compatible with Terraform 1.3 and later.
  required_version = ">= 1.3"
  # Specifies the required version of the Google Cloud provider.
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30"
    }
  }
}
