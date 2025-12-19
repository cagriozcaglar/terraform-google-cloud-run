# <!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
terraform {
  # This module is meant for use with Terraform 1.3+
  required_version = ">= 1.3"

  required_providers {
    # The Google provider is required for this module
    google = {
      source  = "hashicorp/google"
      version = ">= 5.14.0"
    }
  }
}
