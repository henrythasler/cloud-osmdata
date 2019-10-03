variable "region" {
  default = "eu-central-1"
}

variable "project" {
  default = "postgis-server"
}

variable "instance_type" {
  default = "t3a.micro"
}

variable "storage_size" {
  default = "5"
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
  default = "db"
}