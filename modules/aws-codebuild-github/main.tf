resource random_id s3 {
  byte_length = 8
}

variable repo {
  description = "URL to repository"
}

variable name {
  default     = "example-project"
  description = "Name of the project"
}

locals {
  s3_bucket_name            = "${var.name}-${random_id.s3.dec}"
  s3_bucket_name_len        = "${length(local.s3_bucket_name)}"
  s3_bucket_name_normalised = "${substr(local.s3_bucket_name, 0, min(local.s3_bucket_name_len, 63))}"
}

output "s3_bucket_name" {
  value = "${local.s3_bucket_name}"
}

resource "aws_s3_bucket" "default" {
  bucket = "${local.s3_bucket_name_normalised}"
  acl    = "private"
}



resource "aws_iam_role" "default" {
  name = "default"

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

resource "aws_iam_role_policy" "default" {
  role = "${aws_iam_role.default.name}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.default.arn}",
        "${aws_s3_bucket.default.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_codebuild_project" "default" {
  name          = "${var.name}"
  build_timeout = "5"
  service_role  = "${aws_iam_role.default.arn}"
  badge_enabled = true

  artifacts {
    type      = "S3"
    packaging = "ZIP"
    location  = "${aws_s3_bucket.default.bucket}"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type            = "GITHUB"
    location        = "${var.repo}"
    git_clone_depth = 1
  }

  tags = {
    "Environment" = "Test"
    "Terraform"   = "aws-codebuild-github"
  }
}

resource "aws_codebuild_webhook" "default" {
 project_name = "${aws_codebuild_project.default.name}"
}

output "payload_url" {
 value = "${aws_codebuild_webhook.default.payload_url}"
}

output "badge_url" {
  value = "${aws_codebuild_project.default.badge_url}"
}
