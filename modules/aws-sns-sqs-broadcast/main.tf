data aws_iam_policy_document policy {
  statement {
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = ["*"]
  }
}

resource aws_iam_policy this {
  name   = "iam_for_lambda_sqs"
  policy = data.aws_iam_policy_document.policy.json
}

resource aws_iam_role_policy_attachment this {
  count      = local.consumers_count
  role       = var.lambdas[count.index].role_name
  policy_arn = aws_iam_policy.this.arn
}

variable topic_name {}
variable lambdas {
  type = list(object({
    lambda_arn=string,
    role_name=string
  }))
}
variable batch_size {
  default = 1
}

locals {
  consumers_count = length(var.lambdas)
  managed         = basename(path.module)
}

resource aws_sns_topic topic {
  name = var.topic_name
  tags = {
    Name = "${var.topic_name}-sns"
    Managed = local.managed
  }
}

resource aws_sqs_queue queue {
  count = local.consumers_count
  name  = "${var.topic_name}-${count.index}"
  tags  = {
    Name = "${var.topic_name}-sqs"
    Managed = local.managed
  }
}

data aws_iam_policy_document sns2sqs {
  count = local.consumers_count

  statement {
    actions = [
      "sqs:SendMessage"
    ]
    principals {
      type = "AWS"
      identifiers = ["*"]
    }
    resources = [
      aws_sqs_queue.queue[count.index].arn
    ]
    condition {
      test = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        aws_sns_topic.topic.arn
      ]
    }
  }
}

resource aws_sqs_queue_policy this {
  count = local.consumers_count
  queue_url = aws_sqs_queue.queue[count.index].id
  policy = data.aws_iam_policy_document.sns2sqs[count.index].json
}

resource aws_sns_topic_subscription this {
  count     = local.consumers_count
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.queue[count.index].arn
}

resource aws_lambda_event_source_mapping this {
  count             = local.consumers_count
  batch_size        = var.batch_size
  event_source_arn  = aws_sqs_queue.queue[count.index].arn
  enabled           = true
  function_name     = var.lambdas[count.index].lambda_arn
  depends_on        = [aws_iam_role_policy_attachment.this]
}

output sns_arn {
  value = aws_sns_topic.topic.arn
}
