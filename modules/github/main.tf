data "github_repository" "frontend" {
  name = var.frontend_repo_name
}
resource "github_actions_secret" "frontend_access_key" {
  repository  = data.github_repository.frontend.name
  secret_name = "AWS_ACCESS_KEY_ID"
  value       = var.aws_access_key
}

resource "github_actions_secret" "frontend_access_key_secret" {
  repository  = data.github_repository.frontend.name
  secret_name = "AWS_SECRET_ACCESS_KEY"
  value       = var.aws_access_key_secret
}

resource "github_actions_secret" "frontend_bucket" {
  repository  = data.github_repository.frontend.name
  secret_name = "AWS_S3_BUCKET"
  value       = var.frontend_s3_bucket
}

resource "github_actions_secret" "aws_region" {
  repository  = data.github_repository.frontend.name
  secret_name = "AWS_REGION"
  value       = var.aws_region
}

data "github_repository" "backend" {
  name = var.backend_repo_name
}

resource "github_actions_secret" "backend_asg_refresh_access_key" {
  repository  = data.github_repository.backend.name
  secret_name = "AWS_ACCESS_KEY_ID"
  value       = var.asg_resresh_access_key
}

resource "github_actions_secret" "backend_asg_refresh_access_key_secret" {
  repository  = data.github_repository.backend.name
  secret_name = "AWS_SECRET_ACCESS_KEY"
  value       = var.asg_refresh_access_key_secret
}

resource "github_actions_secret" "dockerhub_username" {
  repository  = data.github_repository.backend.name
  secret_name = "DOCKERHUB_USERNAME"
  value       = var.dockerhub_username
}

resource "github_actions_secret" "dockerhub_token" {
  repository  = data.github_repository.backend.name
  secret_name = "DOCKERHUB_TOKEN"
  value       = var.dockerhub_token
}

resource "github_actions_secret" "repository_name" {
  repository  = data.github_repository.backend.name
  secret_name = "REPOSITORY_NAME"
  value       = var.repository_name
}