resource "aws_sesv2_email_identity" "backend" {
  email_identity = var.frontend_domain
}

resource "aws_sesv2_email_identity_mail_from_attributes" "backend" {
  email_identity = aws_sesv2_email_identity.backend.email_identity
  mail_from_domain = "${var.ses_email_subdomain}.${var.frontend_domain}"
}
