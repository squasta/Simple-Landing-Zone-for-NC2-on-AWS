
# Nutanix NC2  pre requisite
# https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Clusters-AWS:aws-clusters-aws-infrastructure-deployment-c.html


# https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Clusters-AWS:aws-clusters-aws-getting-started-c.html
# NC2 CIDR requirements
# You must use the following range of IP addresses for the VPCs and subnets:
# VPC: between /16 and /25, including both
#     Private management subnet: /16 and /25, including both
#     Public subnet: /16 and /25 including both
#     UVM subnets: /16 and /25, including both
#         UVM subnet sizing would depend on the number of UVMs that would need to be deployed. 
#         NC2 supports the network CIDR sizing limits enforced by AWS
# Please don't overlap AWS CIDR with your on-premises network CIDR



# An AWS VPC
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc

resource "aws_vpc" "Terra-VPC" {

  cidr_block       = "10.0.0.0/16"   # CIDR requirements: /16 and /25 including both
  instance_tenancy = "default"
  # if you want to use internal proxy for your NC2 cluster, you need to enable DNS hostnames
  # and DNS support. In any case, NC2 documentation recommends to enable these settings.
  # cf. https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html#vpc-dns-support
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = join("", [var.VPC_NAME,"-",var.AWS_REGION])
  }
}


# NC2 Public Subnet
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet

resource "aws_subnet" "Terra-Public-Subnet" {
  vpc_id                  = aws_vpc.Terra-VPC.id
  cidr_block              = "10.0.1.0/24"   # CIDR requirements: /16 and /25 including both
                                            # a /28 CIDR should be enough. It's the value used if VPC is created through NC2 portal wizard
  availability_zone       = join("", [var.AWS_REGION,"a"])                
  map_public_ip_on_launch = true

  tags = {
    Name = join("", ["NC2-PublicSubnet-",var.AWS_REGION,"a"])
  }
}


# A private subnet for cluster management traffic
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet 

resource "aws_subnet" "Terra-Private-Subnet-Mngt" {
  vpc_id                  = aws_vpc.Terra-VPC.id
  cidr_block              = "10.0.2.0/24"    # CIDR requirements: /16 and /25 including both
                                             # a /25 CIDR should be enough. It's the value used if VPC is created through NC2 portal wizard
  availability_zone       = join("", [var.AWS_REGION,"a"])                 

  tags = {
    Name = join("", ["NC2-PrivateMgntSubnet-",var.AWS_REGION,"a"])
  }
}


# One or more private subnets for User VM (UVM) traffic
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet  

resource "aws_subnet" "Terra-Private-Subnet-UVM1" {
  vpc_id                  = aws_vpc.Terra-VPC.id
  cidr_block              = "10.0.3.0/24"   # CIDR requirements: /16 and /25 including both
  availability_zone       = join("", [var.AWS_REGION,"a"])                   

  tags = {
    ## join function https://developer.hashicorp.com/terraform/language/functions/join
    Name = join("", ["NC2-PrivateSubnet-UVM1-",var.AWS_REGION,"a"])
  }
}


# One or more private subnets for Prism Central VM and MST
# Subnets used for Prism Central and Multicloud Snapshot Technology (MST) must be different
# than the UVM subnet
# cf. https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Clusters-AWS:aws-cluster-protect-requirements-c.html
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet  

resource "aws_subnet" "Terra-Private-Subnet-PC" {
  vpc_id                  = aws_vpc.Terra-VPC.id
  cidr_block              = "10.0.4.0/24"   # CIDR requirements: /16 and /25 including both
  availability_zone       = join("", [var.AWS_REGION,"a"])                       

  tags = {
    ## join function https://developer.hashicorp.com/terraform/language/functions/join
    Name = join("", ["NC2-PrivateSubnet-PC-",var.AWS_REGION,"a"])
  }
}


# Internet Gateway
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "Terra-Internet-Gateway" {
  vpc_id = aws_vpc.Terra-VPC.id
  tags = {
    Name = "NC2-InternetGateway"
  }
}


# Elastic IP resource (EIP) - mandatory for AWS NAT Gateway
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
resource "aws_eip" "Terra-EIP" {
  domain   = "vpc"

  tags = {
    Name = "NC2-EIP"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.Terra-Internet-Gateway]
}


# NAT Gateway
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway
resource "aws_nat_gateway" "Terra-AWS-NAT-GW" {
  allocation_id = aws_eip.Terra-EIP.id
  subnet_id     = aws_subnet.Terra-Public-Subnet.id
  tags = {
    Name = "NC2-NAT-GW"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.Terra-Internet-Gateway]

}


# Route Table for Public Subnet
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table

resource "aws_route_table" "Terra-Public-Route-Table" {
  vpc_id = aws_vpc.Terra-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Terra-Internet-Gateway.id
  }

  tags = {
    Name = "NC2-Route-Table-Public"
  }
}


# Route Table Association for Public Subnet
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "Terra-Public-Route-Table-Association" {
  subnet_id      = aws_subnet.Terra-Public-Subnet.id
  route_table_id = aws_route_table.Terra-Public-Route-Table.id
}


# Route Table for Private Subnet(s)
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
# this is the route table for the private subnets, to go to on-premises network or Internet 
# (communication of cluster with NC2 portal)

resource "aws_route_table" "Terra-Private-Route-Table" {
  vpc_id = aws_vpc.Terra-VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Terra-AWS-NAT-GW.id
  }
  ##### IMPORTANT #####
  # Insert here you internal routes to on-premises network or other networks
  #

  # propagating_vgws = [aws_vpn_gateway.Terra-VPN-GW.id]  # if you have a VPN connection to on-premises network

  tags = {
    Name = "NC2-Route-Table-Private"
  }
}


# Route Table Association for Private Subnet Management
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "Terra-Private-Route-Table-Association-Mngt" {
  subnet_id      = aws_subnet.Terra-Private-Subnet-Mngt.id
  route_table_id = aws_route_table.Terra-Private-Route-Table.id
}


# Route Table Association for Private Subnet UVM1
resource "aws_route_table_association" "Terra-Private-Route-Table-Association-UVM1" {
  subnet_id      = aws_subnet.Terra-Private-Subnet-UVM1.id
  route_table_id = aws_route_table.Terra-Private-Route-Table.id
}


# Route Table Association for Private Subnet PC
resource "aws_route_table_association" "Terra-Private-Route-Table-Association-PC" {
  subnet_id      = aws_subnet.Terra-Private-Subnet-PC.id
  route_table_id = aws_route_table.Terra-Private-Route-Table.id
}



### If there is a Web proxy configured #################
# https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Clusters-AWS:aws-aws-clusters-vpc-endpoints-for-s3-c.html
# AWS VPC private endpoints for S3 and EC2 services must be configured when using a proxy server 
# to communicate with the NC2 console.
# These endpoints can connect to AWS Services privately from your VPC without going through the
# public Internet.


# VPC Endpoint for S3
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint
# resource "aws_vpc_endpoint" "Terra-VPC-Endpoint-S3" {
#   vpc_id       = aws_vpc.Terra-VPC.id
#   service_name = join("", ["com.amazonaws.",var.AWS_REGION,".s3"])    # ex: "com.amazonaws.us-west-2.s3"

#   tags = {
#     Environment = "test"
#   }
# }

# VPC Endpoint for EC2
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint
# resource "aws_vpc_endpoint" "ec2" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = join("", ["com.amazonaws.",var.AWS_REGION,".ec2"])   # ex: "com.amazonaws.us-west-2.ec2"
#   vpc_endpoint_type = "Interface"
#   security_group_ids = [
#     aws_security_group.sg1.id,
#   ]
#   private_dns_enabled = true
# }

###################################################################



#### For NC2 Cluster Protect #####

# Two new AWS S3 buckets with Nutanix IAM role if you want to use 
# the Cluster Protect feature to protect Prism Central, UVM, and volume groups data.
# S3-Bucket
# https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html
# cf. https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Clusters-AWS:aws-cluster-protect-creating-s3-buckets-c.html
# Note: NC2 creates an IAM role with the required permissions to access S3 buckets with the nutanix-clusters prefix.
#       This IAM role is added to the CloudFormation template. 
# cf. https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest 

# Bucket for Prism Central backups
resource "aws_s3_bucket" "Terra-S3-Bucket-PC" {
  bucket_prefix = "nutanix-clusters-mst-pc"

  tags = {
    Name        = "nutanix-clusters-mst-pc"
  }
}

# Ensure that public access to MST PC  S3 buckets is blocked by default
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
resource "aws_s3_bucket_public_access_block" "Terra-S3-Public-Access-Block-PC" {
  bucket = aws_s3_bucket.Terra-S3-Bucket-PC.id 

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

# Controlling versioning on MST PC S3 bucket
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning
resource "aws_s3_bucket_versioning" "Terra-S3-Bucket-PC-Versioning" {
  bucket = aws_s3_bucket.Terra-S3-Bucket-PC.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Set Object Lock to Enable and Default retention period as 31 days.
# This provides WORM configuration for objects to create point-in-time snapshots of Prism Central configuration
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object_lock_configuration
# In the context of AWS S3 Object Lock, there are two modes for retention: `GOVERNANCE` and `COMPLIANCE`.
# `GOVERNANCE` mode allows users with specific permissions to override the retention settings.
# This means that while the objects are protected under normal circumstances, a user with the `s3:BypassGovernanceRetention` permission can change 
# the retention settings or delete the object before the retention period expires. This mode is useful when you want to protect objects from being deleted
# or altered during the retention period, but still need the ability to do so in exceptional circumstances.
# In the context of AWS S3 Object Lock, `COMPLIANCE` mode ensures that a protected object cannot be overwritten or
# deleted by any user, including the root user in your AWS account. Once an object is locked in `COMPLIANCE` mode,
# its retention mode cannot be changed, and its retention period cannot be shortened. 
# This mode is typically used for regulatory compliance, where data must be preserved and not altered for a fixed period of time.
resource "aws_s3_bucket_object_lock_configuration" "Terra-S3-Bucket-PC-Object-Lock" {
  bucket = aws_s3_bucket.Terra-S3-Bucket-PC.id

  rule {
    default_retention {
      mode = "GOVERNANCE"   # Should be COMPLIANCE for regulatory compliance
      days = 31
    }
  }

  depends_on = [ aws_s3_bucket_versioning.Terra-S3-Bucket-PC-Versioning ]
}

# Configure the Object Lifecycle rule to auto-delete older backup data, and the rule scope must be set to apply to all objects in the bucket.
# Also, select the following Lifecycle rule actions:
# - Expire current version of objects: set as 31 days
# - Permanently delete noncurrent versions of objects: set Days after objects become noncurrent to 1 day.
# - Delete expired object, delete markers, or incomplete multipart uploads: Number of days as 1 day.
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration
resource "aws_s3_bucket_lifecycle_configuration" "Terra-S3-Bucket-PC-Lifecycle" {
  bucket = aws_s3_bucket.Terra-S3-Bucket-PC.id

  rule {
    id      = "AutoDeleteOlderBackupData"
    status  = "Enabled"

    expiration {
      days = 31
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }

    abort_incomplete_multipart_upload { 
      days_after_initiation  = 1
    }
  }
}



# Bucket for UVM backups
resource "aws_s3_bucket" "Terra-S3-Bucket-UVM" {
  bucket_prefix = "nutanix-clusters-mst-uvm"

  tags = {
    Name        = "nutanix-clusters-mst-uvm"
  }
}

# Ensure that public access to MST UVM S3 buckets is blocked by default
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
resource "aws_s3_bucket_public_access_block" "Terra-S3-Public-Access-Block-UVM" {
  bucket = aws_s3_bucket.Terra-S3-Bucket-UVM.id 

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

# Controlling versioning on MST UVM S3 bucket
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning
resource "aws_s3_bucket_versioning" "Terra-S3-Bucket-UVM-Versioning" {
  bucket = aws_s3_bucket.Terra-S3-Bucket-UVM.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Set Object Lock to Enable and Default retention period as 31 days.
# This provides WORM configuration for objects to create point-in-time snapshots of Prism Central configuration
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object_lock_configuration
resource "aws_s3_bucket_object_lock_configuration" "Terra-S3-Bucket-UVM-Object-Lock" {
  bucket = aws_s3_bucket.Terra-S3-Bucket-UVM.id

  rule {
    default_retention {
      mode = "GOVERNANCE"   # Should be COMPLIANCE for regulatory compliance
      days = 31
    }
  }

  depends_on = [ aws_s3_bucket_versioning.Terra-S3-Bucket-UVM-Versioning ]
}

# Configure the Object Lifecycle rule to auto-delete older backup data, and the rule scope must be set to apply to all objects in the bucket.
# Also, select the following Lifecycle rule actions:
# - Expire current version of objects: set as 31 days
# - Permanently delete noncurrent versions of objects: set Days after objects become noncurrent to 1 day.
# - Delete expired object, delete markers, or incomplete multipart uploads: Number of days as 1 day.
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration
resource "aws_s3_bucket_lifecycle_configuration" "Terra-S3-Bucket-UVM-Lifecycle" {
  bucket = aws_s3_bucket.Terra-S3-Bucket-UVM.id

  rule {
    id      = "AutoDeleteOlderBackupData"
    status  = "Enabled"

    expiration {
      days = 31
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }

    abort_incomplete_multipart_upload { 
      days_after_initiation  = 1
    }
  }
}




# AWS Security Group for VPC
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group
# resource "aws_default_security_group" "Terra-Security-Group-vpc" {
#   vpc_id = aws_vpc.Terra-VPC.id

#   ingress {
#     protocol  = -1
#     self      = true
#     from_port = 0
#     to_port   = 0
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }



# AWS Security Group for management interfaces	
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

# resource "aws_security_group" "Terra-Security-Group-Mngt" {
#   name        = "NC2-SG-User-Management"
#   description = "Security Group for management interfaces"
#   vpc_id      = aws_vpc.Terra-VPC.id
#   tags = {
#     Name = "NC2 User Management Security Group"
#   }
# }


# AWS Security Group for Internal Management
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

# resource "aws_security_group" "Terra-Security-Group-Internal-Mngt" {
#   name        = "NC2-SG-Internal-Mngt"
#   description = "Security Group for Internal Management"
#   vpc_id      = aws_vpc.Terra-VPC.id

#   tags = {
#     Name = "NC2 Internal Management Security Group"
#   }
# }


# AWS Security Group for PC VMs 
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

# resource "aws_security_group" "Terra-Security-Group-PC" {
#   name        = "NC2-SG-PC"
#   description = "Security Group for PC VMs"
#   vpc_id      = aws_vpc.Terra-VPC.id

#   tags = {
#     Name = "NC2 PC VMs Security Group"
#   }
# }


# AWS Security Group for UVMs 
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

# resource "aws_security_group" "Terra-Security-Group-UVM1" {
#   name        = "NC2-SG-UVM1"
#   description = "Security Group for UVMs"
#   vpc_id      = aws_vpc.Terra-VPC.id

#   tags = {
#     Name = "NC2 User VMs Security Group"
#   }
# }


