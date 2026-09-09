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


data "aws_iam_policy_document" "smoke_lambda_policy" {
  statement {
    sid    = "AllowRevertSSMDocker"
    effect = "Allow"
    actions = [
      "ssm:PutParameter",
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [
      aws_ssm_parameter.docker_sha.arn,
      "${aws_ssm_parameter.docker_sha.arn}:*"
    ]
  }
  statement {
    sid    = "AllowLifecycleActions"
    effect = "Allow"
    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:RecordLifecycleActionHeartbeat",
      "autoscaling:DescribeInstanceRefreshes",
      "autoscaling:CancelInstanceRefresh"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AllowReadRunCommandResult"
    effect = "Allow"
    actions = [
      "ssm:GetCommandInvocation",
      "ssm:SendCommand"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "smoke_lambda" {
  name   = "${var.vpc_name}-revert-docker-ssm"
  policy = data.aws_iam_policy_document.smoke_lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_lambda_smoke" {
  role       = aws_iam_role.lambda_smoke.name
  policy_arn = aws_iam_policy.smoke_lambda.arn
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
      DOCKER_SHA_PARAM        = "${aws_ssm_parameter.docker_sha.name}"
      APP_PORT                = "8080"
      HEALTH_PATH             = "/actuator/health"
      CANCEL_INSTANCE_REFRESH = "true"
    }
  }
}

resource "aws_cloudwatch_event_rule" "asg_hook" {
  name = "${var.vpc_name}-capture-lifecycle-hook"
  event_pattern = jsonencode({
    detail-type = ["EC2 Instance-launch Lifecycle Action"]
    source      = ["aws.autoscaling"]
    detail = {
      AutoScalingGroupName = [aws_autoscaling_group.ec2_asg.name]
      LifecycleHookName    = [aws_autoscaling_lifecycle_hook.ec2_asg.name]
    }
  })
}

resource "aws_cloudwatch_event_target" "target_smoke_lambda" {
  rule      = aws_cloudwatch_event_rule.asg_hook.name
  target_id = "Lambda"
  arn       = aws_lambda_function.smoke_lambda.arn
}

resource "aws_lambda_permission" "allow_invoke_smoke_lambda" {
  statement_id  = "AllowEventBridgeInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.smoke_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.asg_hook.arn
}
