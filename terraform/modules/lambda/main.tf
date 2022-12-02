data "aws_iam_policy_document" "assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "dallePreviewlambdaIam"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:HeadObject",
    ]

    resources = ["${var.bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "lambda" {
  name        = "dallePreviewLambdaPolicy"
  description = "Allow put logs, use s3 to store email and sent emails with SES"
  policy      = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

locals {
  filename = "${path.module}/../../../_build/package.zip"
}

resource "aws_lambda_function" "lambda" {
  filename      = local.filename
  function_name = "dallePreviewLambda"
  role          = aws_iam_role.lambda.arn
  handler       = "main.main"

  source_code_hash = filebase64sha256(local.filename)

  runtime = "python3.7"

  memory_size = 512

  timeout = 60

  environment {
    variables = {
      DALLE_API_KEY = var.dalle_api_key
    }
  }
}