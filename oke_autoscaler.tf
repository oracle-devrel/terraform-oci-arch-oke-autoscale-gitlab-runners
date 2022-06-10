## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "template_file" "autoscaler_deployment" {
  template = "${file("${path.module}/templates/autoscaler.template.yaml")}"
  vars     = {
      autoscaler_image = "${lookup(local.autoscaler_image, var.kubernetes_version)}"
      min_nodes        = "${var.min_number_of_nodes}"
      max_nodes        = "${var.max_number_of_nodes}"
      node_pool_id     = "${module.oci-oke.node_pool.id}"
  }
}

resource "local_file" "autoscaler_deployment" {
  content  = data.template_file.autoscaler_deployment.rendered
  filename = "${path.module}/autoscaler.yaml"
}

resource "null_resource" "deploy_autoscaler" {
  provisioner "local-exec" {
    command = "oci ce cluster create-kubeconfig --region ${var.region} --cluster-id ${module.oci-oke.cluster.id}"
  }
  
  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.autoscaler_deployment.filename}"
  }
  depends_on = [module.oci-oke.cluster, local_file.autoscaler_deployment]
}