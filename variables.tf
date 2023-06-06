## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

variable "tenancy_ocid" {}
variable "compartment_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}


variable "release" {
  description = "Reference Architecture Release (OCI Architecture Center)"
  default     = "1.0"
}

## Networking placement

variable "use_existing_networking" {
  type        = bool
  description = "Use existing networking resources?"
  default     = false
}
variable "vcn_id" {
  type        = string
  description = "ID of the VCN in which to deploy resources"
  default     = ""
}

variable "endpoint_subnet_id" {
  type        = string
  description = "ID of the public subnet in which to deploy OKE endpoint"
  default     = ""
}

variable "workers_subnet_id" {
  type        = string
  description = "ID of the subnet in which to deploy OKE worker nodes"
  default     = ""
}

variable "services_subnet_id" {
  type        = string
  description = "ID of the subnet in which to deploy OKE services"
  default     = ""
}

variable "network_cidrs" {
  type = map(string)

  default = {
    VCN-CIDR                      = "10.20.0.0/16"
    SUBNET-REGIONAL-CIDR          = "10.20.10.0/24"
    LB-SUBNET-REGIONAL-CIDR       = "10.20.20.0/24"
    ENDPOINT-SUBNET-REGIONAL-CIDR = "10.20.0.0/28"
    ALL-CIDR                      = "0.0.0.0/0"
    PODS-CIDR                     = "10.244.0.0/16"
    KUBERNETES-SERVICE-CIDR       = "10.96.0.0/16"
  }
}

## Gitlab runners

variable "gitlab_runner_instances" {
  type        = number
  description = "Number of gitlab instances"
  default     = 1
}

variable "gitlab_runner_namespace" {
  type        = string
  description = "Namespace to use for each instance"
  default     = "default"
}

variable "gitlab_runner_token" {
  type        = string
  description = "Gitlab runner token"
  default     = "gitlab-runner-token"
}


## Autoscaler parameters

variable "min_number_of_nodes" {
  type        = number
  description = "Minimum number of nodes in the node pool"
  default     = 3
}

variable "max_number_of_nodes" {
  type        = number
  description = "Maximum number of nodes in the node pool"
  default     = 10
}

## OKE cluster parameters

variable "cluster_name" {
  type        = string
  description = "Name of OKE cluster"
  default     = "oke-cluster"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
  default     = "v1.26.2"
}

variable "cluster_type" {
  default = "enhanced"
}

variable "oke_public_endpoint" {
  type        = bool
  description = "Is OKE endpoint public?"
  default     = true
}

variable "is_kubernetes_dashboard_enabled" {
  type        = bool
  description = "Enable OKE dashboard?"
  default     = true
}

## Node pool params

variable "pool_name" {
  type        = string
  description = "Name of workers pool name"
  default     = "node-pool"
}

variable "worker_bv_size" {
  type        = number
  description = "Size of the boot volume"
  default     = 50
}

variable "worker_shape" {
  type        = string
  description = "Worker node shape"
  default     = "VM.Standard.E4.Flex"
}

variable "worker_flex_memory" {
  type        = number
  description = "Worker node memory in GB for flex shape"
  default     = 16
}

variable "worker_flex_ocpu" {
  type        = number
  description = "Worker node number of OCPUs for flex shape"
  default     = 2
}

variable "worker_default_image_name" {
  type        = string
  description = "If no Image ID is supplied, use the most recent Oracle Linux 7.9 Image ID"
  default     = "Oracle-Linux-7.9-2022.+"
}

variable "worker_image_id" {
  type        = string
  description = "ID of a custom Image to use when creating worker nodes"
  default     = ""
}

variable "worker_public_key" {
  type        = string
  description = "Public SSH key for worker node access"
  default     = ""
}
