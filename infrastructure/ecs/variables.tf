variable "region" {
  default = "eu-central-1"
}

variable "project" {
  default = "postgis-server"
}

variable "githubProject" {
  default = "https://github.com/henrythasler/docker-aws.git"
}

variable "instance_class" {
  # default = "t2.micro"
  default = "t3a.micro"
}

variable "ssh_key" {
  default = "ec2-postgres"
}

variable "vpc_id" {
}
variable "postgres_password" {}
