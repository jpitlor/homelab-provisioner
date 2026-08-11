provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_record" "subdomain" {
  zone_id = var.cloudflare_zone_id
  name    = "*"
  value   = google_compute_address.vps_ip_address.address
  type    = "A"
}

# resource "cloudflare_record" "minecraft" {
#   zone_id = var.cloudflare_zone_id
#   name    = "_minecraft._tcp"
#   type    = "SRV"
#
#   data {
#     service  = "_minecraft"
#     proto    = "_tls"
#     name     = "minecraft-srv"
#     priority = 0
#     weight   = 0
#     port     = 25565
#     target   = "minecraft.pitlor.dev"
#   }
# }
