# Example: Comprehensive and Secure Cloud Run Service

This example demonstrates how to use the Cloud Run v2 module to deploy a secure, private service with a comprehensive set of features enabled.

It creates all necessary prerequisite resources, including:
*   A dedicated service account for the Cloud Run service to run as.
*   A second service account to be granted invoker permissions.
*   A VPC and Serverless VPC Access connector for private networking.
*   Secrets in Secret Manager to be injected as environment variables and mounted as file volumes.

The module is then instantiated to deploy a Cloud Run service that:
*   Runs with a least-privilege service account.
*   Is only accessible from internal traffic or a load balancer.
*   Connects to a VPC for egress traffic.
*   Has secrets securely mounted as both environment variables and files.
*   Has a liveness probe configured for health checking.
*   Grants explicit IAM invoker permissions to another service account.

## How to use it

1.  **Configure your environment:**
    Ensure you have the Google Cloud SDK installed and authenticated:
