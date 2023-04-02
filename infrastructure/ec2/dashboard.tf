# data "aws_instance" "postgis_server_info" {
#   instance_id = aws_instance.postgis.id
# }

resource "aws_cloudwatch_dashboard" "postgis_server_dashboard" {
  dashboard_name = "ec2-${var.project}"
  dashboard_body = templatefile("${path.module}/dashboard.tftpl", {
    project     = var.project,
    region      = var.region,
    device_name = var.device_name,
    instance_id = aws_instance.postgis.id,
  })
}
