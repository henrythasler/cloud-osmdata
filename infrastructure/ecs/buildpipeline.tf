resource "aws_iam_role" "codebuild_worker_auto_role" {
  name               = "codebuild-worker-auto-role"
  description        = "Role to build ${var.project}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "CodeBuildBasePolicy" {
  name = "CodeBuildBasePolicy-${var.project}-${var.region}"
  description = "Policy to build ${var.project} in ${var.region}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:logs:eu-central-1:324094553422:log-group:/aws/codebuild/${var.project}",
                "arn:aws:logs:eu-central-1:324094553422:log-group:/aws/codebuild/${var.project}:*"
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::codepipeline-${var.region}-*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryPowerUser" {
    role       = "${aws_iam_role.codebuild_worker_auto_role.name}"
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}


resource "aws_iam_role_policy_attachment" "CodeBuildBasePolicy" {
  role       = "${aws_iam_role.codebuild_worker_auto_role.name}"
  policy_arn = "${aws_iam_policy.CodeBuildBasePolicy.arn}"
}



resource "aws_codebuild_project" "CodeBuildProject" {
  name          = "${var.project}"
  description   = "builds ${var.project}"
  build_timeout = "60"
  service_role  = "${aws_iam_role.codebuild_worker_auto_role.arn}"
  badge_enabled = true

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "${var.region}"
    }

    environment_variable {
      name  = "REPOSITORY_URI"
      value = "${aws_ecr_repository.ecr_repository.repository_url}"
    }

    environment_variable {
      name  = "IMAGE_NAME"
      value = "${var.project}"
    }
  }

  source {
    type            = "GITHUB"
    location        = "${var.githubProject}"
    git_clone_depth = 1
    buildspec       = "${var.project}/buildspec.yml"
  }
}


resource "aws_codebuild_webhook" "example" {
  project_name = "${aws_codebuild_project.CodeBuildProject.name}"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "FILE_PATH"
      pattern = "${var.project}"
    }
  }
}

output "badge_url" {
  value = "${aws_codebuild_project.CodeBuildProject.badge_url}"
}

