resource "aws_s3_bucket" "backend_bucket" {
  bucket = var.backend_bucket_name
}


resource "aws_s3_bucket_versioning" "backend_bucket" {
  bucket = var.backend_bucket_name.id
  versioning_configuration {
    status = true
  }
}