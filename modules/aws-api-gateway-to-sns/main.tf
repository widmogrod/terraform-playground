variable sns_arn {}

resource aws_api_gateway_stage test {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.test.id
  deployment_id = aws_api_gateway_deployment.test.id
}

resource aws_api_gateway_rest_api test {
  name        = "Send request to SNS"
  description = "Broadcast request in SNS and then use lambdas to handle them"
}

resource aws_api_gateway_deployment test {
  depends_on  = [aws_api_gateway_integration.test]
  rest_api_id = aws_api_gateway_rest_api.test.id
  stage_name  = "dev"
}

resource aws_api_gateway_resource test {
  rest_api_id = aws_api_gateway_rest_api.test.id
  parent_id   = aws_api_gateway_rest_api.test.root_resource_id
  path_part   = "webhook"
}

resource aws_api_gateway_method test {
  rest_api_id   = aws_api_gateway_rest_api.test.id
  resource_id   = aws_api_gateway_resource.test.id
  http_method   = "POST"
  authorization = "NONE"
}

# resource aws_api_gateway_method_settings s {
#   rest_api_id = aws_api_gateway_rest_api.test.id
#   stage_name  = aws_api_gateway_stage.test.stage_name
#   method_path = "${aws_api_gateway_resource.test.path_part}/${aws_api_gateway_method.test.http_method}"
#
#   settings {
#     metrics_enabled = true
#     logging_level   = "INFO"
#   }
# }

variable region {
  default = "eu-west-1"
}

resource aws_api_gateway_integration test {
  rest_api_id = aws_api_gateway_rest_api.test.id
  resource_id = aws_api_gateway_resource.test.id
  http_method = aws_api_gateway_method.test.http_method

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
  rest_api_id = aws_api_gateway_rest_api.test.id
  resource_id = aws_api_gateway_resource.test.id
  http_method = aws_api_gateway_method.test.http_method
  status_code = "200"
}

resource aws_api_gateway_integration_response test {
  rest_api_id = aws_api_gateway_rest_api.test.id
  resource_id = aws_api_gateway_resource.test.id
  http_method = aws_api_gateway_method.test.http_method
  status_code = aws_api_gateway_method_response.ok.status_code

  response_templates = {
    "application/json" = ""
  }
}

output url {
  value = aws_api_gateway_deployment.test.invoke_url
}
