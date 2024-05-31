# Simple-Landing-Zone-for-NC2-on-AWS
This repo contains terraform code to deploy a simple network landing zone for Nutanix Cloud Cluster (NC2) on AWS

## Prerequisites

- All prerequisites for NC2 : https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Clusters-AWS:aws-clusters-aws-requirements-c.html 

- An AWS Account with enough privileges (create VPC, ...)
- AWS CLI x or >: 
- Terraform CLI 1.5 or > : <https://www.terraform.io/downloads.html>

You can also clone this repo in your AWS Cloud Shell (that has all tools installed)

## Step by step operations

Edit [configuration.tfvars](configuration.tfvars) to define your Azure resources names.

