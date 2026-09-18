data "aws_iam_policy_document" "frontend_bucket_policy" {
  statement {
    sid    = "AllowS3ListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      var.frontend_bucket_arn
    ]
  }
  statement {
    sid    = "Allow3SObjectManagement"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "${var.frontend_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "frontend_bucket_policy" {
  name   = "frontend-bucket-policy"
  policy = data.aws_iam_policy_document.frontend_bucket_policy.json
}

resource "aws_iam_user" "frontend_bucket_user" {
  name = "frontend-bucket-user"
}

resource "aws_iam_user_policy_attachment" "frontend_bucket_user_policy_attachment" {
  user       = aws_iam_user.frontend_bucket_user.name
  policy_arn = aws_iam_policy.frontend_bucket_policy.arn
}

resource "aws_iam_access_key" "frontend_bucket_user_access_key" {
  user = aws_iam_user.frontend_bucket_user.name
}

resource "aws_iam_user" "backend_asg_refresh_user" {
  name = "backend_refresh_asg_user"
}

data "aws_iam_policy_document" "ecs_deploy" {
  statement {
    sid = "AllowDeployECS"
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService"
    ]
    resources = [
      var.ecs_service_arn,
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = ["iam:PassRole"]
    resources = [
     var.esc_task_execution_role
    ]
  }
}

resource "aws_iam_policy" "ecs_deploy" {
  name = "ecs-deploy-policy"
  policy = data.aws_iam_policy_document.ecs_deploy.json
}

resource "aws_iam_user_policy_attachment" "ecs_deploy" {
  user = aws_iam_user.backend_asg_refresh_user.name
  policy_arn = aws_iam_policy.ecs_deploy.arn
}

resource "aws_iam_access_key" "asg-refresh" {
  user = aws_iam_user.backend_asg_refresh_user.name
}
