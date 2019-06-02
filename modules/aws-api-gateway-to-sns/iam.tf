data aws_iam_policy_document role {
  statement {
    actions   = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

data aws_iam_policy_document policy {
  statement {
    actions = [
      "sns:Publish"
    ]
    resources = [
      var.sns_arn
    ]
  }
}

resource aws_iam_role this {
  name               = "iam_for_apigateway_sns_publish=${aws_api_gateway_rest_api.this.name}"
  assume_role_policy = data.aws_iam_policy_document.role.json
}

resource aws_iam_policy this {
  name   = "policy_sns_publish"
  policy = data.aws_iam_policy_document.policy.json
}

resource aws_iam_role_policy_attachment this {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}
