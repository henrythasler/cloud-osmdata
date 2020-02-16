resource "aws_batch_job_definition" "prepare_local_database" {
  name                 = "prepare_local_database"
  type                 = "container"
  container_properties = <<EOF
{
    "command": ["preprocessing.sh"],
    "image": "${var.repository_url}:latest",
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
    "image": "${var.repository_url}:latest",
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
    "image": "${var.repository_url}:latest",
    "memory": 7000,
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
    "image": "${var.repository_url}:latest",
    "memory": 2048,
    "vcpus": 2,
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
    "image": "${var.repository_url}:latest",
    "memory": 2048,
    "vcpus": 2,
    "jobRoleArn": "arn:aws:iam::324094553422:role/ecsTaskExecutionRole",
    "volumes": [],
    "environment": [
        {"name": "BATCH_FILE_TYPE", "value": "script"},
        {"name": "BATCH_FILE_S3_URL", "value": "s3://${aws_s3_bucket_object.production.bucket}/${aws_s3_bucket_object.production.id}"},
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

resource "aws_batch_job_definition" "shp_download" {
  name                 = "shp_download"
  type                 = "container"
  container_properties = <<EOF
{
    "command": ["shp_download.sh"],
    "image": "${var.repository_url}:latest",
    "memory": 2048,
    "vcpus": 2,
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
    "image": "${var.repository_url}:latest",
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
    "image": "${var.repository_url}:latest",
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
    "image": "${var.repository_url}:latest",
    "memory": 2048,
    "vcpus": 2,
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

resource "aws_batch_job_definition" "slice" {
  name = "slice"
  type = "container"
  container_properties = <<EOF
{
    "command": ["slice.sh"],
    "image": "${var.repository_url}:latest",
    "memory": 512,
    "vcpus": 1,
    "jobRoleArn": "arn:aws:iam::324094553422:role/ecsTaskExecutionRole",
    "volumes": [
      {
        "host": {
          "sourcePath": "/gisdata"
        },
        "name": "data"
      }
    ],
    "environment": [
        {"name": "BATCH_FILE_TYPE", "value": "script"},
        {"name": "BATCH_FILE_S3_URL", "value": "s3://${aws_s3_bucket_object.slice.bucket}/${aws_s3_bucket_object.slice.id}"},
        {"name": "GIS_DATA_BUCKET", "value": "${aws_s3_bucket.gis_data_0000.id}"},
        {"name": "LEFT", "value": "8.7890625"},
        {"name": "BOTTOM", "value": "45.33670215"},
        {"name": "RIGHT", "value": "14.41406216"},
        {"name": "TOP", "value": "51.61801655"},
        {"name": "OUT_FILE", "value": "germany-alps.osm.pbf"},
        {"name": "SOURCE_FILE", "value": "europe-latest.osm.pbf"}
    ],
    "mountPoints": [
        {
          "sourceVolume": "data",
          "containerPath": "/gisdata",
          "readOnly": false
        }
    ],
    "ulimits": []
}
EOF
}