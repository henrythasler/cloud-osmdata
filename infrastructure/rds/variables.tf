variable "region" {
  default = "eu-central-1"
}

variable "project" {
  default = "postgis-server"
}
variable "instance_class" {
  default = "db.t2.micro"
}

variable "postgres_password" {}
