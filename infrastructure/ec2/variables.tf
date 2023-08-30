variable "region" {
  default = "eu-central-1"
}

variable "availability_zone" {
  default = "a"
}

variable "project" {
  default = "postgis-ec2"
}

variable "instance_type" {
  default = "t3a.micro"
}

variable "storage_size" {
  default = "16"
}

variable "device_name" {
  default = "/dev/sdg"
}

variable "postgres_password" {}

variable "ssh_key" {
  default = "ec2-postgres"
}

variable "vpc" {}

variable "repository_url" {
  default = "localhost"
}

variable "domain" {
  default = "cyclemap.link"
}

variable "db_prefix" {
  default = "ec2"
}

# database mount location (absolute path incl. '/')
variable "pgdata" {
  default = "/pgdata"
}