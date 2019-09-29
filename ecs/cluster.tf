resource "aws_iam_role" "ecsInstanceRole" {
  name               = "ecsInstanceRole-${var.project}"
  description        = "Role to run EC2-Instances for ${var.project}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerServiceforEC2Role" {
  role = "${aws_iam_role.ecsInstanceRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecsInstanceProfile" {
  name = "ecsInstanceProfile-${var.project}"
  role = "${aws_iam_role.ecsInstanceRole.name}"
}

resource "aws_ecs_cluster" "gis_cluster" {
  name = "gis-cluster"

  setting {
    name = "containerInsights"
    value = "disabled"
  }
}

# Get the latest ECS AMI
data "aws_ami" "latest_ecs" {
  most_recent = true

  filter {
    name = "name"
    values = ["amzn2-ami-ecs-hvm*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }

  owners = ["591542846629"] # AWS
}

resource "aws_security_group" "cluster_security_group" {
  name = "security-group-${var.project}"
  description = "Allow SSH and postgres inbound traffic"
  vpc_id = "${var.vpc_id}"
  ingress {
    # SSH
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # PostgeSQL
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "launch_configuration" {
  name_prefix = "${var.EC2InstanceType}-"
  image_id = "${data.aws_ami.latest_ecs.id}"
  instance_type = "${var.EC2InstanceType}"
  iam_instance_profile = "${aws_iam_instance_profile.ecsInstanceProfile.id}"

  # Networking
  associate_public_ip_address = true

  root_block_device {
    volume_size = 40
    volume_type = "gp2"
  }

  security_groups = ["${aws_security_group.cluster_security_group.id}"]

  key_name = "${var.ssh_key}"
  user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.gis_cluster.name} >> /etc/ecs/ecs.config;echo ECS_BACKEND_HOST= >> /etc/ecs/ecs.config;
EOF
}

resource "aws_autoscaling_group" "gis_cluster_group" {
  name                 = "gis-cluster-autoscaling-group"
  launch_configuration = "${aws_launch_configuration.launch_configuration.name}"

  min_size = 0
  max_size = 1
  desired_capacity = 1
 
  availability_zones = ["eu-central-1a"]
}
