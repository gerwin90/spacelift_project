# ---------- Upload index.html from local file ----------
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  source       = var.index_file
  etag         = filemd5(var.index_file)
  content_type = "text/html; charset=utf-8"

  # Ensure policy is attached before we try to read via CloudFront
  depends_on = [aws_s3_bucket_policy.site]
}
