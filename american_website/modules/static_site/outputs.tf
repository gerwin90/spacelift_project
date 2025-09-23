output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}

output "cdn_domain" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "distribution_id" {
  value = aws_cloudfront_distribution.cdn.id
}
