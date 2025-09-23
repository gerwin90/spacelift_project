# Deploy a static website using S3 + CloudFront + OAC
module "site_prod" {
  source      = "./modules/static_site"
  bucket_name = var.bucket_name
  index_file  = abspath("${path.root}/index.html")
}