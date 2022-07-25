## Copyright (c) 2022 Oracle and/or its affiliates.
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_virtual_network" "oke_vcn" {
  count          = var.use_existing_networking ? 0 : 1
  cidr_block     = lookup(var.network_cidrs, "VCN-CIDR")
  compartment_id = var.compartment_ocid
  display_name   = "OKE_VCN"
  dns_label      = "autoscaleokevcn"
  defined_tags   = local.defined_tags
}

resource "oci_core_subnet" "oke_k8s_endpoint_subnet" {
  count                      = var.use_existing_networking ? 0 : 1
  cidr_block                 = lookup(var.network_cidrs, "ENDPOINT-SUBNET-REGIONAL-CIDR")
  compartment_id             = var.compartment_ocid
  display_name               = "oke-k8s-endpoint-subnet"
  dns_label                  = "endpointsn"
  vcn_id                     = oci_core_virtual_network.oke_vcn[0].id
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.oke_public_route_table[0].id
  dhcp_options_id            = oci_core_virtual_network.oke_vcn[0].default_dhcp_options_id
  security_list_ids          = [oci_core_security_list.oke_endpoint_security_list[0].id]
  defined_tags               = local.defined_tags
}

resource "oci_core_subnet" "oke_nodes_subnet" {
  count                      = var.use_existing_networking ? 0 : 1
  cidr_block                 = lookup(var.network_cidrs, "SUBNET-REGIONAL-CIDR")
  compartment_id             = var.compartment_ocid
  display_name               = "oke-nodes-subnet"
  dns_label                  = "nodesn"
  vcn_id                     = oci_core_virtual_network.oke_vcn[0].id
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.oke_private_route_table[0].id
  dhcp_options_id            = oci_core_virtual_network.oke_vcn[0].default_dhcp_options_id
  security_list_ids          = [oci_core_security_list.oke_nodes_security_list[0].id]
  defined_tags               = local.defined_tags
}

resource "oci_core_subnet" "oke_lb_subnet" {
  count                      = var.use_existing_networking ? 0 : 1
  cidr_block                 = lookup(var.network_cidrs, "LB-SUBNET-REGIONAL-CIDR")
  compartment_id             = var.compartment_ocid
  display_name               = "oke-lb-subnet"
  dns_label                  = "lbsn"
  vcn_id                     = oci_core_virtual_network.oke_vcn[0].id
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.oke_public_route_table[0].id
  dhcp_options_id            = oci_core_virtual_network.oke_vcn[0].default_dhcp_options_id
  security_list_ids          = [oci_core_security_list.oke_lb_security_list[0].id]
  defined_tags               = local.defined_tags
}

resource "oci_core_route_table" "oke_private_route_table" {
  count          = var.use_existing_networking ? 0 : 1
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.oke_vcn[0].id
  display_name   = "oke-private-route-table"

  route_rules {
    description       = "Traffic to the internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.oke_nat_gateway[0].id
  }
  route_rules {
    description       = "Traffic to OCI services"
    destination       = lookup(data.oci_core_services.all_services.services[0], "cidr_block")
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.oke_service_gateway[0].id
  }
  defined_tags = local.defined_tags
}

resource "oci_core_route_table" "oke_public_route_table" {
  count          = var.use_existing_networking ? 0 : 1
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.oke_vcn[0].id
  display_name   = "oke-public-route-table"

  route_rules {
    description       = "Traffic to/from internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.oke_internet_gateway[0].id
  }
  defined_tags = local.defined_tags
}

resource "oci_core_nat_gateway" "oke_nat_gateway" {
  count          = var.use_existing_networking ? 0 : 1
  block_traffic  = "false"
  compartment_id = var.compartment_ocid
  display_name   = "oke-nat-gateway"
  vcn_id         = oci_core_virtual_network.oke_vcn[0].id
  defined_tags   = local.defined_tags
}

resource "oci_core_internet_gateway" "oke_internet_gateway" {
  count          = var.use_existing_networking ? 0 : 1
  compartment_id = var.compartment_ocid
  display_name   = "oke-internet-gateway"
  enabled        = true
  vcn_id         = oci_core_virtual_network.oke_vcn[0].id
  defined_tags   = local.defined_tags
}

resource "oci_core_service_gateway" "oke_service_gateway" {
  count          = var.use_existing_networking ? 0 : 1
  compartment_id = var.compartment_ocid
  display_name   = "oke-service-gateway"
  vcn_id         = oci_core_virtual_network.oke_vcn[0].id
  services {
    service_id = lookup(data.oci_core_services.all_services.services[0], "id")
  }
  defined_tags = local.defined_tags
}

resource "oci_core_security_list" "oke_nodes_security_list" {
  count          = var.use_existing_networking ? 0 : 1
  compartment_id = var.compartment_ocid
  display_name   = "oke-nodes-wrk-seclist"
  vcn_id         = oci_core_virtual_network.oke_vcn[0].id

  # Ingresses
  ingress_security_rules {
    description = "Allow pods on one worker node to communicate with pods on other worker nodes"
    source      = lookup(var.network_cidrs, "SUBNET-REGIONAL-CIDR")
    source_type = "CIDR_BLOCK"
    protocol    = local.all_protocols
    stateless   = false
  }
  ingress_security_rules {
    description = "Inbound SSH traffic to worker nodes"
    source      = lookup(var.network_cidrs, "VCN-CIDR")
    source_type = "CIDR_BLOCK"
    protocol    = local.tcp_protocol_number
    stateless   = false

    tcp_options {
      max = local.ssh_port_number
      min = local.ssh_port_number
    }
  }
  ingress_security_rules {
    description = "TCP access from Kubernetes Control Plane"
    source      = lookup(var.network_cidrs, "ENDPOINT-SUBNET-REGIONAL-CIDR")
    source_type = "CIDR_BLOCK"
    protocol    = local.tcp_protocol_number
    stateless   = false
  }
  ingress_security_rules {
    description = "Path discovery"
    source      = lookup(var.network_cidrs, "ENDPOINT-SUBNET-REGIONAL-CIDR")
    source_type = "CIDR_BLOCK"
    protocol    = local.icmp_protocol_number
    stateless   = false

    icmp_options {
      type = "3"
      code = "4"
    }
  }

  # Egresses
  egress_security_rules {
    description      = "Allow pods on one worker node to communicate with pods on other worker nodes"
    destination      = lookup(var.network_cidrs, "SUBNET-REGIONAL-CIDR")
    destination_type = "CIDR_BLOCK"
    protocol         = local.all_protocols
    stateless        = false
  }
  egress_security_rules {
    description      = "Worker Nodes access to Internet"
    destination      = lookup(var.network_cidrs, "ALL-CIDR")
    destination_type = "CIDR_BLOCK"
    protocol         = local.all_protocols
    stateless        = false
  }
  egress_security_rules {
    description      = "Allow nodes to communicate with OKE to ensure correct start-up and continued functioning"
    destination      = lookup(data.oci_core_services.all_services.services[0], "cidr_block")
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = local.tcp_protocol_number
    stateless        = false

    tcp_options {
      max = local.https_port_number
      min = local.https_port_number
    }
  }
  egress_security_rules {
    description      = "ICMP Access from Kubernetes Control Plane"
    destination      = lookup(var.network_cidrs, "ALL-CIDR")
    destination_type = "CIDR_BLOCK"
    protocol         = local.icmp_protocol_number
    stateless        = false

    icmp_options {
      type = "3"
      code = "4"
    }
  }
  egress_security_rules {
    description      = "Access to Kubernetes API Endpoint"
    destination      = lookup(var.network_cidrs, "ENDPOINT-SUBNET-REGIONAL-CIDR")
    destination_type = "CIDR_BLOCK"
    protocol         = local.tcp_protocol_number
    stateless        = false

    tcp_options {
      max = local.k8s_api_endpoint_port_number
      min = local.k8s_api_endpoint_port_number
    }
  }
  egress_security_rules {
    description      = "Kubernetes worker to control plane communication"
    destination      = lookup(var.network_cidrs, "ENDPOINT-SUBNET-REGIONAL-CIDR")
    destination_type = "CIDR_BLOCK"
    protocol         = local.tcp_protocol_number
    stateless        = false

    tcp_options {
      max = local.k8s_worker_to_control_plane_port_number
      min = local.k8s_worker_to_control_plane_port_number
    }
  }
  egress_security_rules {
    description      = "Path discovery"
    destination      = lookup(var.network_cidrs, "ENDPOINT-SUBNET-REGIONAL-CIDR")
    destination_type = "CIDR_BLOCK"
    protocol         = local.icmp_protocol_number
    stateless        = false

    icmp_options {
      type = "3"
      code = "4"
    }
  }

  defined_tags = local.defined_tags
}

resource "oci_core_security_list" "oke_lb_security_list" {
  count          = var.use_existing_networking ? 0 : 1
  compartment_id = var.compartment_ocid
  display_name   = "oke-lb-seclist"
  vcn_id         = oci_core_virtual_network.oke_vcn[0].id
  defined_tags   = local.defined_tags
}

resource "oci_core_security_list" "oke_endpoint_security_list" {
  count          = var.use_existing_networking ? 0 : 1
  compartment_id = var.compartment_ocid
  display_name   = "oke-k8s-api-endpoint-seclist"
  vcn_id         = oci_core_virtual_network.oke_vcn[0].id

  # Ingresses

  ingress_security_rules {
    description = "External access to Kubernetes API endpoint"
    source      = lookup(var.network_cidrs, "ALL-CIDR")
    source_type = "CIDR_BLOCK"
    protocol    = local.tcp_protocol_number
    stateless   = false

    tcp_options {
      max = local.k8s_api_endpoint_port_number
      min = local.k8s_api_endpoint_port_number
    }
  }
  ingress_security_rules {
    description = "Kubernetes worker to Kubernetes API endpoint communication"
    source      = lookup(var.network_cidrs, "SUBNET-REGIONAL-CIDR")
    source_type = "CIDR_BLOCK"
    protocol    = local.tcp_protocol_number
    stateless   = false

    tcp_options {
      max = local.k8s_api_endpoint_port_number
      min = local.k8s_api_endpoint_port_number
    }
  }
  ingress_security_rules {
    description = "Kubernetes worker to control plane communication"
    source      = lookup(var.network_cidrs, "SUBNET-REGIONAL-CIDR")
    source_type = "CIDR_BLOCK"
    protocol    = local.tcp_protocol_number
    stateless   = false

    tcp_options {
      max = local.k8s_worker_to_control_plane_port_number
      min = local.k8s_worker_to_control_plane_port_number
    }
  }
  ingress_security_rules {
    description = "Path discovery"
    source      = lookup(var.network_cidrs, "SUBNET-REGIONAL-CIDR")
    source_type = "CIDR_BLOCK"
    protocol    = local.icmp_protocol_number
    stateless   = false

    icmp_options {
      type = "3"
      code = "4"
    }
  }

  # Egresses

  egress_security_rules {
    description      = "Allow Kubernetes Control Plane to communicate with OKE"
    destination      = lookup(data.oci_core_services.all_services.services[0], "cidr_block")
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = local.tcp_protocol_number
    stateless        = false

    tcp_options {
      max = local.https_port_number
      min = local.https_port_number
    }
  }
  egress_security_rules {
    description      = "All traffic to worker nodes"
    destination      = lookup(var.network_cidrs, "SUBNET-REGIONAL-CIDR")
    destination_type = "CIDR_BLOCK"
    protocol         = local.tcp_protocol_number
    stateless        = false
  }
  egress_security_rules {
    description      = "Path discovery"
    destination      = lookup(var.network_cidrs, "SUBNET-REGIONAL-CIDR")
    destination_type = "CIDR_BLOCK"
    protocol         = local.icmp_protocol_number
    stateless        = false

    icmp_options {
      type = "3"
      code = "4"
    }
  }

  defined_tags = local.defined_tags
}


# Create NSG when using user defined network to ensure access to OKE Endpoint
resource "oci_core_network_security_group_security_rule" "oke_nsg_rule_6443" {
  count                     = var.use_existing_networking ? 1 : 0
  network_security_group_id = oci_core_network_security_group.oke_nsg[0].id
  direction                 = "INGRESS"
  protocol                  = "6"

  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
  stateless   = false
  tcp_options {
    destination_port_range {
      max = "6443"
      min = "6443"
    }
  }
}

resource "oci_core_network_security_group_security_rule" "oke_nsg_rule_12250" {
  count                     = var.use_existing_networking ? 1 : 0
  network_security_group_id = oci_core_network_security_group.oke_nsg[0].id
  direction                 = "INGRESS"
  protocol                  = "6"

  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
  stateless   = false
  tcp_options {
    destination_port_range {
      max = "12250"
      min = "12250"
    }
  }
}
