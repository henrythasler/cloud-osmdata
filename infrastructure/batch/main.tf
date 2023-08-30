provider "aws" {
  profile = "default"
  region  = var.region
}

# this is where we store the terraform-state.
# Change at least `bucket` to match your account's environment.
# Remove the whole terraform-entry to use a local state.
terraform {
  required_version = ">= 1.5"  
  backend "s3" {
    bucket         = "terraform-state-0000"
    key            = "cloud-osmdata/batch/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.13"
    }
  }
}
