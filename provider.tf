## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

terraform {
  required_version = ">= 1.1"
  required_providers {
    oci = {
      source  = "oracle/oci"
    }
  }
}


provider "oci" {
  alias            = "targetregion"
  tenancy_ocid     = var.tenancy_ocid
  region           = var.region
  fingerprint      = var.fingerprint
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
}

provider "oci" {
  alias                = "homeregion"
  tenancy_ocid         = var.tenancy_ocid
  user_ocid            = var.user_ocid
  fingerprint          = var.fingerprint
  private_key_path     = var.private_key_path
  region               = data.oci_identity_region_subscriptions.home_region_subscriptions.region_subscriptions[0].region_name
  disable_auto_retries = "true"
}
