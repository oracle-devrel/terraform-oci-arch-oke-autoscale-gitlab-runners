## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

locals {
  gr_values = [
      "gitlabUrl=https://gitlab.com",
      "unregisterRunners=true",
      "rbac.create=true"
    ]
  gr_config = <<-EOT
    [[runners]]
      [runners.kubernetes]
        namespace = "{{.Release.Namespace}}"
        image = "ubuntu:16.04"
        poll_timeout = 600
        cpu_request = "0.2"
        memory_request = "512M"
        cpu_request_overwrite_max_allowed = "1"
        memory_request_overwrite_max_allowed = "4096M"
    EOT
  
  http_port_number                        = "80"
  https_port_number                       = "443"
  k8s_api_endpoint_port_number            = "6443"
  k8s_worker_to_control_plane_port_number = "12250"
  ssh_port_number                         = "22"
  tcp_protocol_number                     = "6"
  icmp_protocol_number                    = "1"
  all_protocols                           = "all"

  # List with supported autoscaler images: https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengusingclusterautoscaler.htm
  autoscaler_image = {
    "v1.22.5" = "iad.ocir.io/oracle/oci-cluster-autoscaler:1.22.2-4",
    "v1.21.5" = "iad.ocir.io/oracle/oci-cluster-autoscaler:1.21.1-3"
  }
}
