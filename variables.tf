variable "regions" {
  default     = ["eu-west-1", "us-east-1", "global"]
  type        = list(any)
  description = "The regions to run aws-nuke inside. This variable is populated in the config file"
}

variable "name" {
  default     = "aws-nuker"
  type        = string
  description = "The name of the resources part of the stack"
}

variable "accont_suffix_length" {
  description = "The number of chars after the prefix for account alias"
  default     = 2
}

variable "accont_suffix_special" {
  description = "To include or exclude special char in the suffix"
  default     = false
}

variable "lambda_pgk" {
  description = "The Lambda zip to upload to AWS Lambda"
  default     = "lambda.zip"
}

variable "lambda_cron_schedule" {
  description = "The cron exprations when to trigger the lambda"
  default     = "cron(0 0 ? * FRI *)"
}

