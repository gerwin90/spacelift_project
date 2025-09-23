# We need a root output to display the children module result.

output "cdn_domain" {
  value = module.site_prod.cdn_domain
}
