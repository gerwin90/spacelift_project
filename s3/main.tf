resource "aws_s3_bucket" "spacelift_bucket" {
  bucket = "newspacelift-gkirwan-bucket"
  
  tags = {
    Name        = "spacelift_gkirwan_bucket"
    Environment = "Dev"
  }
}
