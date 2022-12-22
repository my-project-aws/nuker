data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  nuke_config = templatefile("aws-nuke/nuke-config.yml.tmpl", { "ACCOUNT_ID" = data.aws_caller_identity.current.account_id, regions = var.regions })
}

resource "local_file" "nuke_conf" {
  content  = local.nuke_config
  filename = "aws-nuke/nuke-config.yml"
}

resource "null_resource" "create_zip" {
  depends_on = [
    local_file.nuke_conf
  ]
  provisioner "local-exec" {
    command = "zip -ju ./${var.lambda_pgk} src/main ${local_file.nuke_conf.filename}"
  }

  triggers = {
    always_run = timestamp()
  }
}

data "aws_iam_policy_document" "lambda_assume_role" {
  policy_id = "${local.name}-lambda"
  version   = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_logs" {
  policy_id = "${local.name}-lambda-logs-policy"
  version   = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["logs:CreateLogStream", "logs:PutLogEvents"]

    resources = [
      "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${local.name}*:*"
    ]
  }
}
