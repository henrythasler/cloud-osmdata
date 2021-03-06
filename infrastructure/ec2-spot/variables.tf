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
  default = "35"
}

variable "storage_type" {
  default = "gp2"
}

variable "device_name" {
  default = "/dev/sdg"
}

variable "postgres_password" {}

variable "ssh_key" {
  default = "ec2-postgres"
}

variable "vpc_id" {
}

variable "repository_url" {
  default = "localhost"
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