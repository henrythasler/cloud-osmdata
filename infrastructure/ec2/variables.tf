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
  default = "40"
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
