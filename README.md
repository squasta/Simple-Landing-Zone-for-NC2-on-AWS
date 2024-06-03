# Simple-Landing-Zone-for-NC2-on-AWS
This repo contains terraform code to deploy a simple network landing zone for Nutanix Cloud Cluster (NC2) on AWS

<img width='400' src='./images/PlaneLZ.jpeg'/> 

## Prerequisites

- All prerequisites for NC2 : https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Clusters-AWS:aws-clusters-aws-requirements-c.html 
- More information about NC2 on AWS : https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Clusters-AWS:aws-clusters-aws-getting-started-c.html 

- An AWS Account with enough privileges (create VPC, ...)
- AWS CLI 2.15 or >: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html or https://github.com/aws/aws-cli/tree/v2  
- Terraform CLI 1.5 or > : <https://www.terraform.io/downloads.html>

You can also clone this repo in your AWS Cloud Shell (that has all tools installed)


## Step by step operations

Edit [configuration.tfvars](configuration.tfvars) to define your AWS resources names or tags, your AWS region...

You can list your AWS region available using the following command :

```bash
aws ec2 describe-regions --output table
```

The following command gives the region actually used by the CLI regardless of whether environment variables are or are not set:

```bash
aws ec2 describe-availability-zones --output table --query 'AvailabilityZones[0].[RegionName]'
```


If you want to define your own IP ranges, edit [main.tf](main.tf)  (I will change that later to put everything as a variable)
 

1. Terraform Init phase  

```bash
terraform init
```

2. Terraform Plan phase

```bash
terraform plan --var-file=configuration.tfvars
```

3. Terraform deployment phase (add TF_LOG=info at the beginning of the following command line if you want to see what's happen during deployment)

```bash
terraform apply --var-file=configuration.tfvars
```

4. Wait until the end of deployment (It should take less than 1 minute)




