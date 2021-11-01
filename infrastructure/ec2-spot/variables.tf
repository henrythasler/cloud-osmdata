# these must be set individually in a secret.auto.tfvars file
variable "vpc_id" {}
variable "postgres_password" {}
variable "repository_url" {}

# these defaults should work
variable "region" {
  default = "eu-central-1"
}

variable "availability_zone" {
  default = "a"
}

variable "project" {
  default = "postgis-server-spot"
}

variable "instance_type" {
  default = "t3a.micro"
}

variable "storage_size" {
  default = "16"
}

variable "storage_type" {
  default = "gp2"
}

variable "device_name" {
  default = "/dev/sdg"
}

variable "ssh_key" {
  default = "ec2-postgres"
}

variable "domain" {
  default = "cyclemap.link"
}

variable "db_prefix" {
  default = "spot"
}

# database mount location (absolute path incl. '/')
variable "pgdata" {
  default = "/pgdata"
}