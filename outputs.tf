## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

output "cluster_instruction" {
value = <<EOT
1.  Open OCI Cloud Shell.
2.  Execute below command to setup OKE cluster access:
$ oci ce cluster create-kubeconfig --region ${var.region} --cluster-id ${oci_containerengine_cluster.k8_cluster.id}
3.  List gitlab runner deployments:
$ kubectl get deployments --namespace ${var.gitlab_runner_namespace}
EOT
}

output "cluster_context_setup" {
    value = "oci ce cluster create-kubeconfig --region ${var.region} --cluster-id ${oci_containerengine_cluster.k8_cluster.id}"
}

output "list_gr_deployments" {
    value = "kubectl get deployments --namespace ${var.gitlab_runner_namespace}"
}