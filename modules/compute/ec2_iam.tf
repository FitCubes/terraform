data "aws_iam_policy_document" "allow_ec2_assume_role" {
  statement {
    sid     = "DefaultEC2Policy"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_allow_ssm" {
  statement {
    sid    = "AllowReadSSMParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParameterByPath"
    ]
    resources = [
      aws_ssm_parameter.db_address.arn,
      aws_ssm_parameter.db_name.arn,
      aws_ssm_parameter.db_password.arn,
      aws_ssm_parameter.db_username.arn,
      aws_ssm_parameter.redis_address.arn,
      aws_ssm_parameter.jwt_secret.arn
    ]
  }
  statement {
    sid    = "AllowDecrypt"
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = ["*"]
  }
}



resource "aws_iam_policy" "ec2_allow_read_ssm" {
  name        = "${var.vpc_name}-ec2-read-ssm"
  description = "Allow EC2 Read Secrets from SSM"
  policy      = data.aws_iam_policy_document.ec2_allow_ssm.json
}




resource "aws_iam_role" "ec2_ssm_role" {
  name               = "${var.vpc_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.allow_ec2_assume_role.json
}





resource "aws_iam_role_policy_attachment" "ec2_role" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = aws_iam_policy.ec2_allow_read_ssm.arn
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.vpc_name}-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name
}