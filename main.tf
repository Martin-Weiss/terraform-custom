data "local_file" "server-txt" {
        filename = "${path.module}/server.txt"
}

locals {
  instances = csvdecode(data.local_file.server-txt.content)
}

# create registry auth secret
resource "rancher2_secret_v2" "registryconfig-auth-registry01" {
  cluster_id = "local"
  name = "registryconfig-auth-registry01-${var.clustername}"
  namespace = "fleet-default"
  type = "kubernetes.io/basic-auth"
  data = {
    username = var.registryusername
    password = var.registrypassword
  }
}

resource "rancher2_secret_v2" "registryconfig-auth-registry02" {
  cluster_id = "local"
  name = "registryconfig-auth-registry02-${var.clustername}"
  namespace = "fleet-default"
  type = "kubernetes.io/basic-auth"
  data = {
    username = var.registryusername
    password = var.registrypassword
  }
}

resource "rancher2_cluster_v2" "cluster" {
  name = var.clustername
  fleet_namespace = "fleet-default"
  kubernetes_version = var.kubernetesversion
  rke_config {
    registries {
         configs {
           hostname = var.registry01
           insecure = false
           auth_config_secret_name = "registryconfig-auth-registry01-${var.clustername}"
      }
         configs {
           hostname = var.registry02
           insecure = false
           auth_config_secret_name = "registryconfig-auth-registry02-${var.clustername}"
      }
         mirrors {
           endpoints = ["https://${var.registry01}","https://${var.registry02}"]
           hostname = "docker.io"
           rewrites = {
             "^(?:library|)(.*)" = "${var.stage}/docker.io/$1"
           }
      }
         mirrors {
           endpoints = ["https://${var.registry01}","https://${var.registry02}"]
           hostname = "registry.suse.com"
           rewrites = {
             "(.*)" = "${var.stage}/registry.suse.com/$1"
           }
      }
         mirrors {
           endpoints = ["https://${var.registry01}","https://${var.registry02}"]
           hostname = "registry.rancher.com"
           rewrites = {
             "(.*)" = "${var.stage}/registry.rancher.com/$1"
           }
      }
    }
    machine_selector_config {
      config = {
        profile = "cis-1.23"
        protect-kernel-defaults = true
      }
    }
    machine_global_config = <<EOF
cni: "calico"
etcd-expose-metrics: true
cluster-cidr: ${var.clustercidr}
service-cidr: ${var.servicescidr}
EOF
    upgrade_strategy {
      control_plane_concurrency = "1"
      worker_concurrency = "1"
    }
    etcd {
      disable_snapshots = false
      snapshot_schedule_cron = "7 */12 * * *"
      snapshot_retention = 14
    }
  }
}
