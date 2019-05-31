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

locals {
  path = "${path.module}/../../lambdas/test-sns.zip"
}

data "archive_file" "init" {
  type        = "zip"
  source_dir = "${path.module}/../../lambdas/test-sns"
  output_path = local.path
}


resource "aws_lambda_function" "test_lambda" {
  filename         = local.path
  function_name    = "test-sns"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.init.output_base64sha256
  runtime          = "nodejs10.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

output "arn" {
  value = aws_lambda_function.test_lambda.arn
}
output "zip" {
  value = local.path
}
