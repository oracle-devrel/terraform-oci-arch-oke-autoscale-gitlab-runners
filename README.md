# One-click gitlab runner deployment to OKE with node pool autoscaler enabled

## Overview

This TF code will create an OKE cluster with all dependent resources (networking, worker node-pool), deploy cluster autoscalling and Gitlab runners. 

OKE cluster autoscaling is based on deployments resource booking. When booked resources exceed available resources (CPU, memory) on worker nodes, new worker nodes are added automatically to the cluster up to `max_number_of_nodes:10`. When cluster resources are not utilized, number of worker nodes will be decresed down to `min_number_of_nodes:3`.

Gitlab runners will handle pending CI/CD jobs and will book, by default, 0.2 CPU and 512M RAM. These values can be overriden using `KUBERNETES_CPU_REQUEST` and `KUBERNETES_MEMORY_REQUEST` variables. Default values can be modified in `locals.tf`.

## Prerequisites:

1. OCI account with rights to:
    - manage dynamic groups
    - manage policies
    - manage network resources
    - manage OKE clusters
    - manage compute resources
    - manage resource manager service

    **Note:** 

    - If you don't have access to an OCI tenancy you can register [here](https://www.oracle.com/cloud/free/) for a free trial.
    
    - In case you plan to use existing OCI network resources, make sure [these](https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfig.htm#securitylistconfig) requirements are met.

2. Gitlab account.
    - required for Gitlab Runner registration token

## Deployment:

You may use below link and take advantage of one click deployment to Oracle Cloud via OCI Resource Manager Service.

[![Deploy to OCI](https://docs.oracle.com/en-us/iaas/Content/Resources/Images/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/robo-cap/oci-oke-autoscale-gitlab-runners/archive/refs/tags/v0.0.1.zip)


## Check status

Connect to OCI cloud shell and execute below commands:

    $ oci ce cluster create-kubeconfig --cluster-id <oke_cluster_id>
    $ kubectl get deployments --all-namespaces

Confirm deployed gitlab runners are available in runners section of Gitlab Project CI/CD Settings.

Validate the deployment using `gitlab-ci.yml` file in `samples` directory.
