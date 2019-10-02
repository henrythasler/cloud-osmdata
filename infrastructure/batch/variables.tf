variable "region" {
  default = "eu-central-1"
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