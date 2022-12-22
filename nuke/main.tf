locals {
  name       = var.name
  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.id
}

resource "random_string" "account_suffix" {
  length      = var.accont_suffix_length
  special     = var.accont_suffix_special
  lower       = true
  min_numeric = 2
}
# To avoid just displaying a account ID, which might gladly be ignored by humans, it is required to actually set an Account Alias for your account. Otherwise aws-nuke will abort.
resource "aws_iam_account_alias" "alias" {
  account_alias = format("sandbox-env-%s", random_string.account_suffix.id)
}

resource "aws_iam_role" "lambda" {
  name               = "${local.name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "lambda_logs" {
  name   = "${local.name}-lambda-logs"
  policy = data.aws_iam_policy_document.lambda_logs.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  depends_on = [aws_iam_role.lambda, aws_iam_policy.lambda_logs]
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_logs.arn
}

resource "aws_iam_role_policy_attachment" "lambda_access" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_cloudwatch_log_group" "aws_nuker_lambda_log" {
  name              = "/aws/lambda/${local.name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_event_rule" "cron_schedule" {
  name                = replace("${local.name}-cron_schedule", "/(.{0,64}).*/", "$1")
  description         = "This event will run according to a schedule for Lambda ${local.name}"
  schedule_expression = var.lambda_cron_schedule
}

resource "aws_lambda_function" "aws_nuker" {
  depends_on = [
    null_resource.create_zip
  ]
  filename         = var.lambda_pgk
  function_name    = local.name
  role             = aws_iam_role.lambda.arn
  handler          = "main"
  runtime          = "go1.x"
  source_code_hash = var.lambda_pgk
  memory_size      = 512
  timeout          = 900
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatchEvents"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.aws_nuker.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron_schedule.arn
}

resource "aws_cloudwatch_event_target" "run_every_friday" {
  rule      = aws_cloudwatch_event_rule.cron_schedule.name
  target_id = "run_every_friday"
  arn       = aws_lambda_function.aws_nuker.arn
}

