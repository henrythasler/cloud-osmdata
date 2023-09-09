data "aws_route53_zone" "primary" {
  name = "${var.domain}"
}

resource "aws_route53_record" "db_record" {
  zone_id = "${data.aws_route53_zone.primary.zone_id}"
  name    = "${var.db_prefix}.${var.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_instance.postgis.private_dns}"]
}
