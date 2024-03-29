data "aws_instance" "postgis_server_info" {
  instance_id = "${aws_spot_instance_request.postgis.spot_instance_id}"
}

# data "template_file" "dashboard" {
#   template = "${file("dashboard.tpl")}"
#   vars = {
#     project = "${var.project}"
#     region = "${var.region}"
#     instance_id = "${aws_spot_instance_request.postgis.spot_instance_id}"
#     device_name = "${var.device_name}"
#   }
# }

resource "aws_cloudwatch_dashboard" "postgis_server_dashboard" {
  dashboard_name = "ec2-${var.project}"
  dashboard_body = templatefile("dashboard.tpl", {
    project = "${var.project}",
    region = "${var.region}",
    instance_id = "${aws_spot_instance_request.postgis.spot_instance_id}",
    device_name = "${var.device_name}",
  })  
  #"${data.template_file.dashboard.rendered}"
}