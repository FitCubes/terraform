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


data "aws_iam_policy_document" "backend_asg_refresh" {
  statement {
    sid    = "AllowRefreshInstances"
    effect = "Allow"
    actions = [
      "autoscaling:StartInstanceRefresh",
      "autoscaling:CancelInstanceRefresh",
      "autoscaling:DescribeInstanceRefreshes",
      "autoscaling:DescribeAutoScalingGroups"
    ]
    resources = [
      var.asg_arn
    ]
  }
}

resource "aws_iam_policy" "asg_refresh" {
  name   = "asg_refresh_policy"
  policy = data.aws_iam_policy_document.backend_asg_refresh.json
}
resource "aws_iam_user" "backend_asg_refresh_user" {
  name = "backend_refresh_asg_user"
}

resource "aws_iam_user_policy_attachment" "asg_refresh" {
  user       = aws_iam_user.backend_asg_refresh_user.name
  policy_arn = aws_iam_policy.asg_refresh.arn
}

resource "aws_iam_access_key" "asg-refresh" {
  user = aws_iam_user.backend_asg_refresh_user.name
}