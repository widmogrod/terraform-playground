data aws_iam_policy_document role {
  statement {
    actions   = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data aws_iam_policy_document policy {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource aws_iam_role this {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.role.json
}

resource aws_iam_policy this {
  name   = "iam_for_lambda_logs"
  policy = data.aws_iam_policy_document.policy.json
}

resource aws_iam_role_policy_attachment this {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

variable directory {}
variable name {}

locals {
  path = "${var.directory}/${var.name}.zip"
  managed = basename(path.module)
}

data archive_file init {
  type        = "zip"
  source_dir = "${var.directory}/${var.name}"
  output_path = local.path
}

resource aws_lambda_function test_lambda {
  filename         = local.path
  function_name    = var.name
  role             = aws_iam_role.this.arn
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

output lambda_arn {
  value = aws_lambda_function.test_lambda.arn
}
output role_arn {
  value = aws_iam_role.this.arn
}
output role_name {
  value = aws_iam_role.this.name
}
