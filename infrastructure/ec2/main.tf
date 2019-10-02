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
    key            = "cloud-osmdata/ec2/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

data "aws_ami" "amazonlinux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0*"]
  }

  filter {
    name   = "description"
    values = ["*gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }  

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
      name = "architecture"
      values = ["x86_64"]
  }

  owners = ["137112412989"] # Amazon
}

resource "aws_instance" "postgis" {
  ami           = "${data.aws_ami.amazonlinux.id}"
  instance_type = "${var.instance_type}"

  tags = {
    Name = "osmdata"
  }
}