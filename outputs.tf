output "lambda_arn" {
  description = "The ARN of the Lambda Function"
  value       = aws_iam_role.lambda.arn
}

output "lambda_id" {
  description = "The ID of the Lambda Function"
  value       = aws_iam_role.lambda.id
}

output "lambda_name" {
  description = "The name of the Lambda Function"
  value       = aws_iam_role.lambda.name
}

output "account_alias" {
  description = "The account aliast"
  value       = aws_iam_account_alias.alias.account_alias
}

output "lambda_role_arn" {
  description = "The ARN of the lambda role"
  value       = aws_iam_role.lambda.arn
}

output "lambda_cloudwatch_logs" {
  description = "The log group arn"
  value       = aws_cloudwatch_log_group.aws_nuker_lambda_log.arn
}
