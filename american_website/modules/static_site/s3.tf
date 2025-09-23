# ---------- S3 ----------
resource "aws_s3_bucket" "site" {
  bucket        = var.bucket_name
  force_destroy = true
  tags          = local.project_tags
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
