## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "template_file" "autoscaler_deployment" {
  template = "${file("${path.module}/templates/autoscaler.template.yaml")}"
  vars     = {
      autoscaler_image = "${lookup(local.autoscaler_image, var.kubernetes_version)}"
      min_nodes        = "${var.min_number_of_nodes}"
      max_nodes        = "${var.max_number_of_nodes}"
      node_pool_id     = "${oci_containerengine_node_pool.nodepool.id}"
  }
}

resource "local_file" "autoscaler_deployment" {
  content  = data.template_file.autoscaler_deployment.rendered
  filename = "${path.module}/autoscaler.yaml"
}

resource "null_resource" "deploy_autoscaler" {
  provisioner "local-exec" {
    command = "oci ce cluster create-kubeconfig --region ${var.region} --cluster-id ${oci_containerengine_cluster.k8_cluster.id}"
  }
  
  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.autoscaler_deployment.filename}"
  }
  depends_on = [oci_containerengine_cluster.k8_cluster, oci_containerengine_node_pool.nodepool, local_file.autoscaler_deployment]
}