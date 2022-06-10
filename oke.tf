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

module "oci-oke" {
  providers        = { oci = oci.targetregion }
  source           = "github.com/oracle-devrel/terraform-oci-arch-oke"
  tenancy_ocid     = var.tenancy_ocid
  compartment_ocid = var.compartment_ocid
  oke_cluster_name = var.cluster_name
  k8s_version      = var.kubernetes_version
  pool_name        = var.pool_name
  node_shape       = var.worker_shape
  node_ocpus       = var.worker_flex_ocpu
  node_memory      = var.worker_flex_memory
  node_count       = var.min_number_of_nodes
  ssh_public_key   = var.worker_public_key
  node_image_id    = var.worker_image_id != "" ? var.worker_image_id : data.oci_core_images.default_images.images[0].id

  node_pool_boot_volume_size_in_gbs = var.worker_bv_size

  pods_cidr        = lookup(var.network_cidrs, "PODS-CIDR")
  services_cidr    = lookup(var.network_cidrs, "KUBERNETES-SERVICE-CIDR")
  
  cluster_options_add_ons_is_kubernetes_dashboard_enabled = var.is_kubernetes_dashboard_enabled
  
  use_existing_vcn              = true
  vcn_id                        = var.use_existing_networking ? var.vcn_id : oci_core_virtual_network.oke_vcn[0].id
  is_api_endpoint_subnet_public = true
  api_endpoint_subnet_id        = var.use_existing_networking ? var.endpoint_subnet_id : oci_core_subnet.oke_k8s_endpoint_subnet[0].id
  api_endpoint_nsg_ids          = var.use_existing_networking ? tolist([oci_core_network_security_group.oke_nsg[0].id]) : []
  is_lb_subnet_public           = true                            
  lb_subnet_id                  = var.use_existing_networking ? var.services_subnet_id : oci_core_subnet.oke_lb_subnet[0].id
  is_nodepool_subnet_public     = false
  nodepool_subnet_id            = var.use_existing_networking ? var.workers_subnet_id : oci_core_subnet.oke_nodes_subnet[0].id
  
  defined_tags                  = { "oke-${random_id.tag.hex}.autoscaler"= "true", "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}

