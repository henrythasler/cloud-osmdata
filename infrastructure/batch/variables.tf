variable "region" {
  default = "eu-central-1"
}

variable "availability_zone" {
  default = "a"
}

variable "project" {
  default = "gisdata-batch"
}

variable "repository_url" {
  default = "localhost"
}

variable "postgres_user" {
  default = "postgres"
}

variable "script_location" {
  default = "./../../processing/"
}

variable "database_local" {
  default = "local"
}
variable "database_shapes" {
  default = "shapes"
}

variable "device_name" {
  default = "/dev/xvdcz"
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

variable "postgres_password" {}

variable "postgis_hostname" {
  default = "db.cyclemap.link"
}

variable "vpc_id" {
}