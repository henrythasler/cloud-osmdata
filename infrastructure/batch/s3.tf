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
