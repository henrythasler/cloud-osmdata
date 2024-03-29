data "aws_vpc" "gis" {
  filter {
    name   = "tag:Name"
    values = ["${var.vpc}"]
  }
}
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2-security-group-${var.project}"
  description = "Allow only outbound traffic"
  vpc_id      = data.aws_vpc.gis.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "setup" {
  template = file("setup.sh.tpl")
  vars = {
    device_name        = var.device_name
    docker_volume_size = var.docker_volume_size
  }
}

data "aws_ami" "amazonlinux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-2.0*ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["591542846629"]
}

resource "aws_launch_template" "gis_batch_launchtemplate" {
  name     = "gis-batch-launchtemplate"
  # image_id = "ami-0895a12593a7b3a0b"
  image_id                = data.aws_ami.amazonlinux.id

  # instance_type           = "a1.medium"
  # vpc_security_group_ids  = ["${aws_security_group.ec2_security_group.id}"]

  block_device_mappings {
    device_name = var.device_name

    ebs {
      delete_on_termination = "true"
      volume_size           = var.volume_size
      volume_type           = "gp2"
    }
  }
  # ebs_optimized           = "false"
  # user_data = base64encode(data.template_file.setup.rendered)
}

