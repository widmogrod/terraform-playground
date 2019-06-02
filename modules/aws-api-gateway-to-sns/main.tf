variable sns_arn {}

resource aws_api_gateway_stage this {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
}

resource aws_api_gateway_rest_api this {
  name        = "github-webhook-to-sns"
  description = "Broadcast request in SNS and then use lambdas to handle them"
}

resource aws_api_gateway_deployment this {
  depends_on  = [aws_api_gateway_integration.this]
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = "dev"
}

resource aws_api_gateway_resource this {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "webhook"
}

resource aws_api_gateway_method this {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.this.id
  http_method   = "POST"
  authorization = "NONE"
}

# resource aws_api_gateway_method_settings s {
#   rest_api_id = aws_api_gateway_rest_api.this.id
#   stage_name  = aws_api_gateway_stage.this.stage_name
#   method_path = "${aws_api_gateway_resource.this.path_part}/${aws_api_gateway_method.this.http_method}"
#
#   settings {
#     metrics_enabled = true
#     logging_level   = "INFO"
#   }
# }

variable region {
  default = "eu-west-1"
}

resource aws_api_gateway_integration this {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this.http_method

  type        = "AWS"
  credentials = aws_iam_role.this.arn
  uri         = "arn:aws:apigateway:${var.region}:sns:path//"
  integration_http_method = "POST"
  passthrough_behavior    = "NEVER"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  # Transforms the incoming XML request to JSON
  request_templates = {
    "application/json" = <<EOF
Action=Publish&TopicArn=$util.urlEncode('${var.sns_arn}')&Message=$util.urlEncode($input.body)
EOF
  }
}

resource aws_api_gateway_method_response ok {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this.http_method
  status_code = "200"
}

resource aws_api_gateway_integration_response this {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.this.id
  http_method = aws_api_gateway_method.this.http_method
  status_code = aws_api_gateway_method_response.ok.status_code

  response_templates = {
    "application/json" = ""
  }
}

output url {
  value = aws_api_gateway_deployment.this.invoke_url
}
