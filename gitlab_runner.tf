## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "local_file" "gitlab_runner_installer" {
  count       = var.gitlab_runner_instances
  content     = templatefile("${path.module}/templates/installGitlabRunner.template", {
    namespace             = var.gitlab_runner_namespace,
    gitlab_runner_name    = format("gr-%s", count.index),
    values                = concat(local.gr_values, tolist(["runnerRegistrationToken=${var.gitlab_runner_token}", "runners.name=runner${count.index}", "runners.tags=\"demo\\,runner${count.index}\""])),
    config                = local.gr_config
  })
  filename    = format("install_gitlab-runner_%s.sh", count.index)
}

resource null_resource "ensure_cluster_access" {
  
  provisioner "local-exec" {
    command = "oci ce cluster create-kubeconfig --region ${var.region} --cluster-id ${oci_containerengine_cluster.k8_cluster.id}"
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}
resource null_resource "install_gitlab_runner" {
  count     = var.gitlab_runner_instances

  provisioner "local-exec" {
    command = "chmod +x install_gitlab-runner_${count.index}.sh"
  }

  provisioner "local-exec" {
    command = "/bin/bash install_gitlab-runner_${count.index}.sh"
  }
  
  depends_on = [local_file.gitlab_runner_installer, null_resource.deploy_autoscaler, null_resource.ensure_cluster_access]
  
  triggers = {
    values = local_file.gitlab_runner_installer[count.index].content
    instances = var.gitlab_runner_instances
  }
}
