resource "null_resource" "copy-test-file" {

  for_each = { for inst in local.instances : inst.servername => inst }

  connection {
    type     = "ssh"
    host     = each.value.servername
    user     = var.username
    password = var.password
  }

  provisioner "file" {
    source      = "files/rootCA.suse.crt"
    destination = "/etc/pki/trust/anchors/rootCA.suse.crt"
  }

}

resource "null_resource" "update-ca-certificates" {

  for_each = { for inst in local.instances : inst.servername => inst }

  provisioner "remote-exec" {
    connection {
      host = each.value.servername
      user = var.username
      password = var.password
    }

    inline = ["update-ca-certificates"]
  }
}

resource "null_resource" "registration" {

  for_each = { for inst in local.instances : inst.servername => inst }

  provisioner "remote-exec" {
    when = create
    connection {
      host = each.value.servername
      user = var.username
      password = var.password
    }

    inline = each.value.role == "master" ? [
      format("%s %s",
        rancher2_cluster_v2.cluster.cluster_registration_token[0]["insecure_node_command"],
        join(" ", formatlist("--%s", split(",", "etcd,controlplane")))
      )
    ] : [
      format("%s %s",
        rancher2_cluster_v2.cluster.cluster_registration_token[0]["insecure_node_command"],
        join(" ", formatlist("--%s", split(",", "worker")))
      )
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    connection {
      host     = self.triggers.host
      agent    = true
      user     = self.triggers.username
      password = self.triggers.password
    }

    inline = [
      "sudo sed -i 's#rm -rf /var/lib/kubelet#rm -rf /var/lib/kubelet || true#g' /usr/local/bin/rke2-uninstall.sh",
      "sudo rancher-system-agent-uninstall.sh",
      "sudo rke2-uninstall.sh"
    ]
  }

}
