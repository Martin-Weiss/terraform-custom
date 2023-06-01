# Configure the Rancher2 provider to admin
provider "rancher2" {
  api_url    = var.api_url
  access_key = var.access_key
  secret_key = var.secret_key
}
terraform {
  required_providers {
    rancher2 = {
      source = "rancher/rancher2"
      version = "3.0.0"
    }
  }
}
