variable topic_name {}
variable lambdas {
  type = list(string)
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

resource aws_sns_topic_subscription user_updates_sqs_target {
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
  function_name     = var.lambdas[count.index]
}
