data "aws_iam_policy_document" "example" {
  statement {
    actions   = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
  # statement {
  #   actions = [
  #     "sqs:ReceiveMessage",
  #     "sqs:DeleteMessage",
  #     "sqs:GetQueueAttributes",
  #     "logs:CreateLogGroup",
  #     "logs:CreateLogStream",
  #     "logs:PutLogEvents"
  #   ]
  #   resources = ["*"]
  # }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.example.json
}

variable directory {}
variable name {}

locals {
  path = "${var.directory}/${var.name}.zip"
  managed = basename(path.module)
}

data "archive_file" "init" {
  type        = "zip"
  source_dir = "${var.directory}/${var.name}"
  output_path = local.path
}


resource "aws_lambda_function" "test_lambda" {
  filename         = local.path
  function_name    = "${var.name}"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.init.output_base64sha256
  runtime          = "nodejs10.x"

  environment {
    variables = {
      foo = "bar"
    }
  }

  tags = {
    Managed = local.managed
  }
}

output "arn" {
  value = aws_lambda_function.test_lambda.arn
}
output "zip" {
  value = local.path
}
