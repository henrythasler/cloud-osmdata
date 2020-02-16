data "aws_ami" "amazonlinux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0*"]
  }

  filter {
    name   = "description"
    values = ["*gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["137112412989"] # Amazon
}

resource "aws_security_group" "ec2_security_group" {
  name        = "ec2-security-group-${var.project}"
  description = "Allow SSH and postgres inbound traffic"
  vpc_id      = "${var.vpc_id}"
  # ingress {
  #   # SSH
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  ingress {
    # PostgeSQL
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "ec2-${var.project}"
  role = "${aws_iam_role.ec2_instance_role.name}"
}
resource "aws_iam_role" "ec2_instance_role" {
  name               = "ec2-${var.project}"
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
  role = "${aws_iam_role.ec2_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# FIXME: Limit permissions to 'cloudwatch:PutMetricData'
resource "aws_iam_role_policy_attachment" "CloudWatchFullAccess" {
  role = "${aws_iam_role.ec2_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}


data "aws_subnet_ids" "subnets" {
  vpc_id = "${var.vpc_id}"
}

data "template_file" "setup" {
  template = "${file("setup.sh.tpl")}"
  vars = {
    project = "${var.project}"
    postgres_password = "${var.postgres_password}"
    region = "${var.region}"
    repository_url = "${var.repository_url}"
    device_name = "${var.device_name}"
    pgdata = "${var.pgdata}"
  }
}

resource "aws_instance" "postgis" {
  ami = "${data.aws_ami.amazonlinux.id}"
  instance_type = "${var.instance_type}"
  key_name = "${var.ssh_key}"
  iam_instance_profile = "${aws_iam_instance_profile.instance_profile.name}"
  availability_zone = "${var.region}${var.availability_zone}"

  tags = {
    Name = "${var.project}"
  }

  root_block_device {
    volume_size = "${tolist(data.aws_ami.amazonlinux.block_device_mappings)[0].ebs.volume_size}"
  }

  associate_public_ip_address = true
  vpc_security_group_ids = ["${aws_security_group.ec2_security_group.id}"]

  user_data = "${data.template_file.setup.rendered}"
}


resource "aws_ebs_volume" "database_volume" {
  availability_zone = "${var.region}${var.availability_zone}"
  size = "${var.storage_size}"
}

resource "aws_volume_attachment" "database_volume_attachment" {
  device_name = "${var.device_name}"
  instance_id = "${aws_instance.postgis.id}"
  volume_id = "${aws_ebs_volume.database_volume.id}"
}

output "instance" {
  value = "${aws_instance.postgis.public_ip}"
}
