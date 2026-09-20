resource "aws_cloudwatch_log_group" "lambda_smoke" {
  name              = var.log_group_lamdba_smoke
  retention_in_days = 7
}

data "aws_iam_policy_document" "lambda_smoke_role" {
  statement {
    sid     = "AllowAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_smoke" {
  name               = "lambda-smoke-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_smoke_role.json
}

resource "aws_iam_role_policy_attachment" "basic_lambda_policy" {
  role       = aws_iam_role.lambda_smoke.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "smoke" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/smoke-test"
  output_path = "${path.module}/lambda/smoke-test.zip"
}

resource "aws_lambda_function" "smoke_lambda" {
  filename      = data.archive_file.smoke.output_path
  function_name = "${var.vpc_name}-smoke-lambda"
  role          = aws_iam_role.lambda_smoke.arn
  runtime       = "python3.12"
  handler       = "handler.lambda_handler"
  memory_size   = var.lambda_memody_size

  timeout          = 300
  source_code_hash = data.archive_file.smoke.output_base64sha256

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.lambda_smoke.name
  }

  environment {
    variables = {
      TEST_DOMAIN      = "${var.backend_domain}"
      SMOKE_CHECK_PATH = "/api/auth/login"
      MAX_ATTEMPTS     = "15"
    }
  }
}
