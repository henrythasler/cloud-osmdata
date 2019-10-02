variable "region" {
  default = "eu-central-1"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "postgres_password" {}
variable "postgres_user" {
  default = "postgres"
}