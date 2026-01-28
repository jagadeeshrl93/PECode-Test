# PowerShell Error Fix:
# If you get "terraform is not recognized" error, use: .\terraform init
# This is because Windows PowerShell doesn't load commands from current location by default

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4"
    }
  }
}
