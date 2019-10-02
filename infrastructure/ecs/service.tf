resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole-${var.project}"
  description        = "Role to run ${var.project}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AmazonECSTaskExecutionRolePolicy" {
  role = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "template_file" "container_definitions" {
  template = "${file("postgis-server.tpl")}"
  vars = {
    postgres_password = "${var.postgres_password}"
    project = "${var.project}"
    repository_url = "${aws_ecr_repository.ecr_repository.repository_url}"
  }
}

resource "aws_ecs_task_definition" "postgis_server_task" {
  family = "${var.project}"
  container_definitions = "${data.template_file.container_definitions.rendered}"
  task_role_arn = "${aws_iam_role.ecsTaskExecutionRole.arn}"
  execution_role_arn = "${aws_iam_role.ecsTaskExecutionRole.arn}"
#   cpu = 2048
  memory = 950
  requires_compatibilities = ["EC2"]
}

resource "aws_ecs_service" "postgis_service" {
  name = "postgis"
  cluster = "${aws_ecs_cluster.gis_cluster.name}"
  task_definition = "${aws_ecs_task_definition.postgis_server_task.id}"
  desired_count = 1
  deployment_controller {
    type = "ECS"
  }
}
