resource "aws_s3_bucket" "spacelift_bucket" {
  bucket = "terraform-ai-analyzer-gkirwan-bucket"
  
  tags = {
    Name        = "terraform-ai-analyzer-gkirwan-bucket"
    Environment = "Dev"
  }
}
