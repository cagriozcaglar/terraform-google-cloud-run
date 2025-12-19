# The terraform block is used to configure aspects of Terraform's behavior.
terraform {
  # The required_providers block specifies the providers required by the current module.
  required_providers {
    # The google provider is used to interact with the many resources supported by Google Cloud Platform.
    google = {
      source  = "hashicorp/google"
      version = "~> 5.14"
    }
  }
}
