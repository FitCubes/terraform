terraform {
  backend "s3" {
    bucket       = "backendbucketfircubes"
    key          = "terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
  default_tags {
    tags = {
      Environment = "dev"
      App         = "FitCubes"
    }
  }
}
