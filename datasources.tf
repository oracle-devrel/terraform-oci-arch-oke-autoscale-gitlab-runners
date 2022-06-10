## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

data "oci_identity_availability_domains" "ads" {
  provider       = oci.targetregion
  compartment_id = var.compartment_ocid
}

data oci_core_images "default_images" {
  provider       = oci.targetregion
  compartment_id = var.compartment_ocid

  filter {
    name   = "display_name"
    regex  = true
    values = [var.worker_default_image_name]
  }
}

data "oci_identity_tenancy" "existing" {
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_regions" "existing" {
  filter {
    name   = "key"
    values = [data.oci_identity_tenancy.existing.home_region_key]
  }
}

data "oci_core_subnet" "worker_subnet" {
  provider  = oci.targetregion
  count     = var.use_existing_networking ? 1 : 0
  subnet_id = var.workers_subnet_id
}

data "oci_identity_compartment" "home_compartment" {
  id = var.compartment_ocid
}

data "oci_identity_compartment" "network_compartment" {
  id = var.use_existing_networking ? data.oci_core_subnet.worker_subnet[0].compartment_id : var.compartment_ocid
}

data "oci_core_services" "all_services" {
  provider = oci.targetregion
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

data "oci_identity_region_subscriptions" "home_region_subscriptions" {
  tenancy_id = var.tenancy_ocid

  filter {
    name   = "is_home_region"
    values = [true]
  }
}
