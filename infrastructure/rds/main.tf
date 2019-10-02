provider "aws" {
  version = "~> 2.16"
  profile = "default"
  region  = "${var.region}"
}

# this is where we store the terraform-state.
# Change at least `bucket` to match your account's environment.
# Remove the whole terraform-entry to use a local state.
terraform {
  backend "s3" {
    bucket         = "terraform-state-0000"
    key            = "cloud-osmdata/rds/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

resource "aws_db_instance" "osmdata" {
  engine                       = "postgres"
  engine_version               = "11.2"
  identifier                   = "${var.project}"
  instance_class               = "${var.instance_class}"
  allocated_storage            = 40
  storage_type                 = "gp2"
  username                     = "postgres"
  password                     = "${var.postgres_password}"
  name                         = "world"
  performance_insights_enabled = true
  skip_final_snapshot          = true
  monitoring_interval          = 1
  publicly_accessible          = true
}
