# Configure the Rancher2 provider to admin
provider "rancher2" {
  api_url    = "https://rancher.suse"
  access_key = "token-shl86"
  secret_key = "nmll6h48cj6klljqldgwkcpf9r28kgccrblx4n5vqtjkb9hzttxfz8"
}
terraform {
  required_providers {
    rancher2 = {
      source = "rancher/rancher2"
      version = "3.0.0"
    }
  }
}
