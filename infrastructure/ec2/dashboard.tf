data "aws_instance" "postgis_server_info" {
  instance_id = "${aws_instance.postgis.id}"
}

data "template_file" "dashboard" {
  template = "${file("dashboard.tpl")}"
  vars = {
    project = "${var.project}"
    region = "${var.region}"
    instance_id = "${aws_instance.postgis.id}"
    device_name = "${var.device_name}"
  }
}

resource "aws_cloudwatch_dashboard" "postgis_server_dashboard" {
  dashboard_name = "ec2-${var.project}"
  dashboard_body = "${data.template_file.dashboard.rendered}"
}