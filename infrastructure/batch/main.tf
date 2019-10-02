provider "aws" {
  version = "~> 2.16"
  profile = "default"
  region  = "${var.region}"
}

# this is where we store the terraform-state.
# Change at least `bucket` to match your account's environment.
# Remove the whole terraform-entry to use a local state.
terraform {
  backend "s3" {
    bucket         = "terraform-state-0000"
    key            = "cloud-osmdata/batch/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

resource "aws_s3_bucket" "gis_data_0000" {
  bucket        = "gis-data-0000"
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket_object" "preprocessing" {
  bucket = "${aws_s3_bucket.gis_data_0000.id}"
  key    = "scripts/preprocessing.sh"
  source = "${var.script_location}preprocessing.sh"
  etag   = "${filemd5("${var.script_location}preprocessing.sh")}"
}

resource "aws_s3_bucket_object" "import" {
  bucket = "${aws_s3_bucket.gis_data_0000.id}"
  key    = "scripts/import.sh"
  source = "${var.script_location}import.sh"
  etag   = "${filemd5("${var.script_location}import.sh")}"
}

resource "aws_s3_bucket_object" "download" {
  bucket = "${aws_s3_bucket.gis_data_0000.id}"
  key    = "scripts/download.sh"
  source = "${var.script_location}download.sh"
  etag   = "${filemd5("${var.script_location}download.sh")}"
}

resource "aws_s3_bucket_object" "mapping" {
  bucket = "${aws_s3_bucket.gis_data_0000.id}"
  key    = "imposm/mapping.yaml"
  source = "./../../imposm/mapping.yaml"
  etag   = "${filemd5("./../../imposm/mapping.yaml")}"
}

resource "aws_s3_bucket_object" "postprocessing" {
  bucket = "${aws_s3_bucket.gis_data_0000.id}"
  key    = "scripts/postprocessing.sh"
  source = "${var.script_location}postprocessing.sh"
  etag   = "${filemd5("${var.script_location}postprocessing.sh")}"
}

resource "aws_s3_bucket_object" "production" {
  bucket = "${aws_s3_bucket.gis_data_0000.id}"
  key    = "scripts/production.sh"
  source = "${var.script_location}production.sh"
  etag   = "${filemd5("${var.script_location}production.sh")}"
}

resource "aws_s3_bucket_object" "shp_download" {
  bucket = "${aws_s3_bucket.gis_data_0000.id}"
  key    = "scripts/shp_download.sh"
  source = "${var.script_location}shp_download.sh"
  etag   = "${filemd5("${var.script_location}shp_download.sh")}"
}

resource "aws_s3_bucket_object" "shp_import" {
  bucket = "${aws_s3_bucket.gis_data_0000.id}"
  key    = "scripts/shp_import.sh"
  source = "${var.script_location}shp_import.sh"
  etag   = "${filemd5("${var.script_location}shp_import.sh")}"
}

resource "aws_s3_bucket_object" "shp_postprocessing" {
  bucket = "${aws_s3_bucket.gis_data_0000.id}"
  key    = "scripts/shp_postprocessing.sh"
  source = "${var.script_location}shp_postprocessing.sh"
  etag   = "${filemd5("${var.script_location}shp_postprocessing.sh")}"
}

resource "aws_s3_bucket_object" "shp_water" {
  bucket = "${aws_s3_bucket.gis_data_0000.id}"
  key    = "scripts/shp_water.sh"
  source = "${var.script_location}shp_water.sh"
  etag   = "${filemd5("${var.script_location}shp_water.sh")}"
}

resource "aws_batch_job_definition" "prepare_local_database" {
  name                 = "prepare_local_database"
  type                 = "container"
  container_properties = <<EOF
{
    "command": ["preprocessing.sh"],
    "image": "324094553422.dkr.ecr.eu-central-1.amazonaws.com/postgis-client:latest",
    "memory": 512,
    "vcpus": 1,
    "jobRoleArn": "arn:aws:iam::324094553422:role/ecsTaskExecutionRole",
    "volumes": [],
    "environment": [
        {"name": "BATCH_FILE_TYPE", "value": "script"},
        {"name": "BATCH_FILE_S3_URL", "value": "s3://${aws_s3_bucket_object.preprocessing.bucket}/${aws_s3_bucket_object.preprocessing.id}"},
        {"name": "POSTGIS_HOSTNAME", "value": "${var.postgis_hostname}"},
        {"name": "POSTGIS_USER", "value": "${var.postgres_user}"},
        {"name": "DATABASE_NAME", "value": "${var.database_local}"},
        {"name": "GIS_DATA_BUCKET", "value": "${aws_s3_bucket.gis_data_0000.id}"},
        {"name": "PGPASSWORD", "value": "${var.postgres_password}"}
    ],
    "mountPoints": [],
    "ulimits": []
}
EOF
}

resource "aws_batch_job_definition" "download_pbf" {
  name = "download_pbf"
  type = "container"
  container_properties = <<EOF
{
    "command": ["download.sh"],
    "image": "324094553422.dkr.ecr.eu-central-1.amazonaws.com/postgis-client:latest",
    "memory": 512,
    "vcpus": 1,
    "jobRoleArn": "arn:aws:iam::324094553422:role/ecsTaskExecutionRole",
    "volumes": [],
    "environment": [
        {"name": "BATCH_FILE_TYPE", "value": "script"},
        {"name": "BATCH_FILE_S3_URL", "value": "s3://${aws_s3_bucket_object.download.bucket}/${aws_s3_bucket_object.download.id}"},
        {"name": "GIS_DATA_BUCKET", "value": "${aws_s3_bucket.gis_data_0000.id}"},
        {"name": "DOWNLOAD_URL", "value": "http://download.geofabrik.de/europe/germany/bayern/oberfranken-latest.osm.pbf"},
        {"name": "OBJECT_NAME", "value": "oberfranken-latest.osm.pbf"}
    ],
    "mountPoints": [],
    "ulimits": []
}
EOF
}

resource "aws_batch_job_definition" "import_into_database" {
  name                 = "import_into_database"
  type                 = "container"
  container_properties = <<EOF
{
    "command": ["import.sh"],
    "image": "324094553422.dkr.ecr.eu-central-1.amazonaws.com/postgis-client:latest",
    "memory": 8192,
    "vcpus": 2,
    "jobRoleArn": "arn:aws:iam::324094553422:role/ecsTaskExecutionRole",
    "volumes": [],
    "environment": [
        {"name": "IMPORT_FILE", "value": "oberfranken-latest.osm.pbf"},
        {"name": "BATCH_FILE_TYPE", "value": "script"},
        {"name": "BATCH_FILE_S3_URL", "value": "s3://${aws_s3_bucket_object.import.bucket}/${aws_s3_bucket_object.import.id}"},
        {"name": "POSTGIS_HOSTNAME", "value": "${var.postgis_hostname}"},
        {"name": "POSTGIS_USER", "value": "${var.postgres_user}"},
        {"name": "DATABASE_NAME", "value": "${var.database_local}"},
        {"name": "PGPASSWORD", "value": "${var.postgres_password}"},
        {"name": "GIS_DATA_BUCKET", "value": "${aws_s3_bucket.gis_data_0000.id}"}
    ],
    "mountPoints": [],
    "ulimits": []
}
EOF
}


resource "aws_batch_job_definition" "postprocessing" {
  name = "postprocessing"
  type = "container"
  container_properties = <<EOF
{
    "command": ["postprocessing.sh"],
    "image": "324094553422.dkr.ecr.eu-central-1.amazonaws.com/postgis-client:latest",
    "memory": 512,
    "vcpus": 4,
    "jobRoleArn": "arn:aws:iam::324094553422:role/ecsTaskExecutionRole",
    "volumes": [],
    "environment": [
        {"name": "BATCH_FILE_TYPE", "value": "script"},
        {"name": "BATCH_FILE_S3_URL", "value": "s3://${aws_s3_bucket_object.postprocessing.bucket}/${aws_s3_bucket_object.postprocessing.id}"},
        {"name": "POSTGIS_HOSTNAME", "value": "${var.postgis_hostname}"},
        {"name": "POSTGIS_USER", "value": "${var.postgres_user}"},
        {"name": "DATABASE_NAME", "value": "${var.database_local}"},
        {"name": "PGPASSWORD", "value": "${var.postgres_password}"}
    ],
    "mountPoints": [],
    "ulimits": []
}
EOF
}

resource "aws_batch_job_definition" "production" {
  name = "production"
  type = "container"
  container_properties = <<EOF
{
    "command": ["production.sh"],
    "image": "324094553422.dkr.ecr.eu-central-1.amazonaws.com/postgis-client:latest",
    "memory": 512,
    "vcpus": 4,
    "jobRoleArn": "arn:aws:iam::324094553422:role/ecsTaskExecutionRole",
    "volumes": [],
    "environment": [
        {"name": "BATCH_FILE_TYPE", "value": "script"},
        {"name": "BATCH_FILE_S3_URL", "value": "s3://${aws_s3_bucket_object.production.bucket}/${aws_s3_bucket_object.production.id}"},
        {"name": "POSTGIS_HOSTNAME", "value": "${var.postgis_hostname}"},
        {"name": "POSTGIS_USER", "value": "${var.postgres_user}"},
        {"name": "DATABASE_NAME", "value": "${var.database_local}"},
        {"name": "PGPASSWORD", "value": "${var.postgres_password}"}
    ],
    "mountPoints": [],
    "ulimits": []
}
EOF
}

resource "aws_batch_job_definition" "shp_download" {
  name                 = "shp_download"
  type                 = "container"
  container_properties = <<EOF
{
    "command": ["shp_download.sh"],
    "image": "324094553422.dkr.ecr.eu-central-1.amazonaws.com/postgis-client:latest",
    "memory": 512,
    "vcpus": 1,
    "jobRoleArn": "arn:aws:iam::324094553422:role/ecsTaskExecutionRole",
    "volumes": [],
    "environment": [
        {"name": "BATCH_FILE_TYPE", "value": "script"},
        {"name": "BATCH_FILE_S3_URL", "value": "s3://${aws_s3_bucket_object.shp_download.bucket}/${aws_s3_bucket_object.shp_download.id}"},
        {"name": "GIS_DATA_BUCKET", "value": "${aws_s3_bucket.gis_data_0000.id}"}
    ],
    "mountPoints": [],
    "ulimits": []
}
EOF
}

resource "aws_batch_job_definition" "shp_import" {
  name = "shp_import"
  type = "container"
  container_properties = <<EOF
{
    "command": ["shp_import.sh"],
    "image": "324094553422.dkr.ecr.eu-central-1.amazonaws.com/postgis-client:latest",
    "memory": 2048,
    "vcpus": 2,
    "jobRoleArn": "arn:aws:iam::324094553422:role/ecsTaskExecutionRole",
    "volumes": [],
    "environment": [
        {"name": "BATCH_FILE_TYPE", "value": "script"},
        {"name": "BATCH_FILE_S3_URL", "value": "s3://${aws_s3_bucket_object.import.bucket}/${aws_s3_bucket_object.shp_import.id}"},
        {"name": "POSTGIS_HOSTNAME", "value": "${var.postgis_hostname}"},
        {"name": "POSTGIS_USER", "value": "${var.postgres_user}"},
        {"name": "SHAPE_DATABASE_NAME", "value": "${var.database_shapes}"},
        {"name": "PGPASSWORD", "value": "${var.postgres_password}"},
        {"name": "GIS_DATA_BUCKET", "value": "${aws_s3_bucket.gis_data_0000.id}"}
    ],
    "mountPoints": [],
    "ulimits": []
}
EOF
}

resource "aws_batch_job_definition" "shp_postprocessing" {
  name                 = "shp_postprocessing"
  type                 = "container"
  container_properties = <<EOF
{
    "command": ["shp_postprocessing.sh"],
    "image": "324094553422.dkr.ecr.eu-central-1.amazonaws.com/postgis-client:latest",
    "memory": 2048,
    "vcpus": 2,
    "jobRoleArn": "arn:aws:iam::324094553422:role/ecsTaskExecutionRole",
    "volumes": [],
    "environment": [
        {"name": "BATCH_FILE_TYPE", "value": "script"},
        {"name": "BATCH_FILE_S3_URL", "value": "s3://${aws_s3_bucket_object.import.bucket}/${aws_s3_bucket_object.shp_postprocessing.id}"},
        {"name": "POSTGIS_HOSTNAME", "value": "${var.postgis_hostname}"},
        {"name": "POSTGIS_USER", "value": "${var.postgres_user}"},
        {"name": "SHAPE_DATABASE_NAME", "value": "${var.database_shapes}"},
        {"name": "PGPASSWORD", "value": "${var.postgres_password}"}
    ],
    "mountPoints": [],
    "ulimits": []
}
EOF
}

resource "aws_batch_job_definition" "shp_water" {
  name = "shp_water"
  type = "container"
  container_properties = <<EOF
{
    "command": ["shp_water.sh"],
    "image": "324094553422.dkr.ecr.eu-central-1.amazonaws.com/postgis-client:latest",
    "memory": 1024,
    "vcpus": 1,
    "jobRoleArn": "arn:aws:iam::324094553422:role/ecsTaskExecutionRole",
    "volumes": [],
    "environment": [
        {"name": "BATCH_FILE_TYPE", "value": "script"},
        {"name": "BATCH_FILE_S3_URL", "value": "s3://${aws_s3_bucket_object.import.bucket}/${aws_s3_bucket_object.shp_water.id}"},
        {"name": "POSTGIS_HOSTNAME", "value": "${var.postgis_hostname}"},
        {"name": "POSTGIS_USER", "value": "${var.postgres_user}"},
        {"name": "SHAPE_DATABASE_NAME", "value": "${var.database_shapes}"},
        {"name": "PGPASSWORD", "value": "${var.postgres_password}"},
        {"name": "GIS_DATA_BUCKET", "value": "${aws_s3_bucket.gis_data_0000.id}"},
        {"name": "SHAPEFOLDER", "value": "data/shp/simplified-water-polygons-split-3857"},
        {"name": "SHAPEFILE", "value": "simplified_water_polygons"},
        {"name": "GRID", "value": "grid_coarse"},
        {"name": "RESOLUTION", "value": "1024"},
        {"name": "OUTPUT", "value": "water_gen"}
    ],
    "mountPoints": [],
    "ulimits": []
}
EOF
}
