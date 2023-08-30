# these must be set individually in a secret.auto.tfvars file
variable "vpc" {}
variable "postgres_password" {}
variable "repository_url" {}  # postgis-client

# these defaults should work
variable "region" {
  default = "eu-central-1"
}

variable "availability_zone" {
  default = "a"
}

variable "project" {
  default = "gisdata-batch"
}

variable "postgres_user" {
  default = "postgres"
}

variable "script_location" {
  default = "./../../processing/"
}

variable "poly_location" {
  default = "./../../poly/"
}

variable "database_local" {
  default = "local"
}

variable "database_shapes" {
  default = "shapes"
}

variable "device_name" {
  default = "/dev/xvda"
}

variable "volume_size" {
  default = "64"
}

variable "docker_volume_size" {
  default = "60"
}

variable "gisdata" {
  default = "/gisdata"
}

variable "postgis_hostname" {
  default = "spot.cyclemap.link"
}
