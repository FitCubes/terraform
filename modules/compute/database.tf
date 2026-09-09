
resource "aws_db_subnet_group" "postgres" {
  name       = "${var.vpc_name}-subnet-group"
  subnet_ids = [for subnet in aws_subnet.database : subnet.id]
}

resource "aws_security_group" "db" {
  name   = "${var.vpc_name}-db-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "${var.vpc_name}-db-sg"
  }
}

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
    rule_name                = "default"
    target_vault_name        = aws_backup_vault.main.name
    enable_continuous_backup = true
    schedule                 = "cron(0 2 * * ? *)"
    lifecycle {
      delete_after = 3
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
