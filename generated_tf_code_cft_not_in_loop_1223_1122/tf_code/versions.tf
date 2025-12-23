# The terraform block is used to configure aspects of Terraform's behavior.
# It includes settings like required providers and their versions.
terraform {
  # Specifies the required providers for this module.
  # Terraform will download these providers if they are not already present.
  required_providers {
    # The Google Provider is required for managing Google Cloud resources.
    google = {
      # Source of the provider, in the format 'namespace/name'.
      source = "hashicorp/google"
      # Version constraint for the provider. A more recent version is specified
      # to ensure stability and access to the latest features, potentially fixing
      # intermittent planner failures seen in previous versions.
      version = ">= 5.12.0"
    }
  }
}
