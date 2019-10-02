variable "region" {
  default = "eu-central-1"
}

variable "project" {
  default = "postgis-server"
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

variable "postgres_password" {}

variable "postgis_hostname" {
  default = "localhost"
}