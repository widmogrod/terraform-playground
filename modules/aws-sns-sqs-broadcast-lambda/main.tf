variable consumers_count {}
variable topic_name {}

locals {
  managed = basename(path.module)
}

resource aws_sns_topic topic {
  name = var.topic_name

  tags = {
    Name = "${var.topic_name}-sns"
    Managed = local.managed
  }
}

resource aws_sqs_queue queue {
  count = var.consumers_count
  name = "${var.topic_name}-${count.index}"

  tags = {
    Name = "${var.topic_name}-sqs"
    Managed = local.managed
  }
}

resource aws_sns_topic_subscription user_updates_sqs_target {
  count = var.consumers_count
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.queue[count.index].arn
}

output consumer_sqs_arn {
  value = aws_sqs_queue.queue.*.arn
}
