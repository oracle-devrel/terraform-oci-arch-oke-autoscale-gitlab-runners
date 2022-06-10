## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_identity_tag_namespace" "cluster_tag_namespace" {
    provider       = oci.homeregion
    compartment_id = var.compartment_ocid
    description    = "Tag namespace for OKE worker nodes"
    name           = "oke-${random_id.tag.hex}"
}

resource "oci_identity_tag" "cluster_tag" {
    provider         = oci.homeregion
    tag_namespace_id = oci_identity_tag_namespace.cluster_tag_namespace.id
    description      = "Tag to identify worker nodes in the OKE cluster"
    name             = "autoscaler"
}


resource "oci_core_network_security_group" "oke_nsg" {
    provider       = oci.targetregion
    count          = var.use_existing_networking ? 1 : 0
    compartment_id = var.compartment_ocid
    vcn_id         = var.vcn_id
}


resource "oci_containerengine_cluster" "k8_cluster" {
  provider           = oci.targetregion
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.kubernetes_version
  name               = var.cluster_name
  vcn_id             = var.use_existing_networking ? var.vcn_id : oci_core_virtual_network.oke_vcn[0].id
  endpoint_config {
    is_public_ip_enabled = var.oke_public_endpoint
    subnet_id            = var.use_existing_networking ? var.endpoint_subnet_id : oci_core_subnet.oke_k8s_endpoint_subnet[0].id
    nsg_ids              = var.use_existing_networking ? tolist([oci_core_network_security_group.oke_nsg[0].id]) : []
  }
  options {
    add_ons {
      is_kubernetes_dashboard_enabled = var.is_kubernetes_dashboard_enabled
    }

    kubernetes_network_config {
      pods_cidr     = lookup(var.network_cidrs, "PODS-CIDR")
      services_cidr = lookup(var.network_cidrs, "KUBERNETES-SERVICE-CIDR")
    }

    service_lb_subnet_ids = var.use_existing_networking ? tolist([var.services_subnet_id,]) : tolist([oci_core_subnet.oke_lb_subnet[0].id,])
  }
  defined_tags   = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}


resource "oci_containerengine_node_pool" "nodepool" {
  provider           = oci.targetregion
  compartment_id     = var.compartment_ocid
  cluster_id         = oci_containerengine_cluster.k8_cluster.id

  kubernetes_version = oci_containerengine_cluster.k8_cluster.kubernetes_version
  name               = var.pool_name

  node_config_details {
      dynamic "placement_configs" {
        iterator = pc
        for_each = data.oci_identity_availability_domains.ads.availability_domains
        content {
            availability_domain = pc.value.name
            subnet_id           = var.use_existing_networking ? var.workers_subnet_id : oci_core_subnet.oke_nodes_subnet[0].id
        }
    }
    size = var.min_number_of_nodes
  }

  node_source_details {
    image_id                = var.worker_image_id != "" ? var.worker_image_id : data.oci_core_images.default_images.images[0].id
    source_type             = "image"
    boot_volume_size_in_gbs = var.worker_bv_size
  }

  node_shape    = var.worker_shape
  dynamic "node_shape_config" {
      iterator  = ns
      for_each  = contains(["VM.Standard.E3.Flex", "VM.Standard.E4.Flex", "VM.Standard.A1.Flex"], var.worker_shape) ? [true] : []
      content {
          memory_in_gbs = var.worker_flex_memory
          ocpus         = var.worker_flex_ocpu
      }
  }

  ssh_public_key = var.worker_public_key
  defined_tags   = { "oke-${random_id.tag.hex}.autoscaler"= "true", "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

