data "aws_iam_policy_document" "backup_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role" "backup_role" {
  name               = "backup-role"
  assume_role_policy = data.aws_iam_policy_document.backup_role.json
}

resource "aws_iam_role_policy_attachment" "example" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_role.name
}

resource "aws_db_instance" "main" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = var.postgres_version
  instance_class         = var.postgres_instance
  username               = var.postgres_username
  password               = var.postgres_password
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  db_name                = var.postgres_db_name
  tags = {
    Backup = "True"
  }
}


resource "aws_backup_vault" "main" {
  name = "${var.vpc_name}-backup-vault"
}

resource "aws_backup_plan" "main" {
  name = "${var.vpc_name}-backup"
  rule {
    rule_name         = "default"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 2 * * ? *)"
    lifecycle {
      delete_after = 7
    }
  }
}

resource "aws_backup_selection" "name" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = var.vpc_name
  plan_id      = aws_backup_plan.main.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "True"
  }
}