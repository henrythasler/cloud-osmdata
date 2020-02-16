data "aws_subnet_ids" "subnets" {
  vpc_id = "${var.vpc_id}"
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs-${var.project}"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
        "Service": "ec2.amazonaws.com"
        }
    }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role" {
  role       = "${aws_iam_role.ecs_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_role" {
  name = "ecs-${var.project}"
  role = "${aws_iam_role.ecs_instance_role.name}"
}

resource "aws_iam_role" "aws_batch_service_role" {
  name               = "batch-${var.project}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "batch.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "aws_batch_service_role" {
  role = "${aws_iam_role.aws_batch_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_batch_compute_environment" "gis_batch_environment" {
  compute_environment_name = "${var.project}"

  compute_resources {
    instance_role = "${aws_iam_instance_profile.ecs_instance_role.arn}"

    instance_type = [
      "m3.medium",
    ]

    ec2_key_pair = "ec2-postgres"

    max_vcpus           = 4
    min_vcpus           = 1
    desired_vcpus       = 1

    allocation_strategy = "BEST_FIT"
    bid_percentage      = 0

    security_group_ids = [
      "${aws_security_group.ec2_security_group.id}",
    ]

    subnets = "${data.aws_subnet_ids.subnets.ids}"
    type = "EC2"

    launch_template { 
      launch_template_id = "${aws_launch_template.gis_batch_launchtemplate.id}"
      version = "${aws_launch_template.gis_batch_launchtemplate.latest_version}"
    }
  }

  service_role = "${aws_iam_role.aws_batch_service_role.arn}"

  type         = "MANAGED"
  depends_on   = ["aws_iam_role_policy_attachment.aws_batch_service_role"]
}

# resource "aws_batch_job_queue" "gis_batch_queue" {
#   name                 = "${var.project}"
#   state                = "ENABLED"
#   priority             = 1
#   compute_environments = ["${aws_batch_compute_environment.gis_batch_environment.arn}"]
#   depends_on   = [
#     "aws_batch_compute_environment.gis_batch_environment"
#     ]
# }
