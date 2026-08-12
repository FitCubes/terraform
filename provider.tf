terraform {
  backend "s3" {
    bucket       = "backendbucketfircubes18234"
    key          = "terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = "dev"
      App         = "FitCubes"
    }
  }
}


provider "github" {
  token = var.github_token
  owner = var.github_owner
}

provider "cloudflare" {
  api_token = var.cloudflare_token
}