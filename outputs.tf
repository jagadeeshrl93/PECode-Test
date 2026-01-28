output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.target.id
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.alerts.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.remediate.function_name
}