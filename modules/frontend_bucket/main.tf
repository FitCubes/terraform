data "cloudflare_ip_ranges" "ip" {

}

resource "aws_s3_bucket" "frontend_bucket" {
  bucket        = var.frontend_bucket_name
  force_destroy = true

}

data "aws_iam_policy_document" "frontend_bucket_policy" {
  statement {
    sid       = "PublicReadGetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend_bucket.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = concat(data.cloudflare_ip_ranges.ip.ipv6_cidrs, data.cloudflare_ip_ranges.ip.ipv4_cidrs)
    }
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_bucket" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = data.aws_iam_policy_document.frontend_bucket_policy.json

  depends_on = [aws_s3_bucket_public_access_block.frontend_bucket]
}

resource "aws_s3_bucket_website_configuration" "frontend_bucket" {
  bucket = aws_s3_bucket.frontend_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}