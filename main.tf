
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


# AWS VPC
# cf. https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
# cf https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest

# module "vpc" {
#   source = "terraform-aws-modules/vpc/aws"
#   version = "5.8.1"

#   name = "NC2-vpc"
#   cidr = "10.0.0.0/16"
#
# # eu-west-3	= Paris Region
#
#   # azs             = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
#   # private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
#   # public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
#
#   azs             = ["eu-west-3a"]
#   private_subnets = ["10.0.1.0/24"]
#   public_subnets  = ["10.0.2.128/28"]
#
#   enable_nat_gateway = true
#   enable_vpn_gateway = false
#
#   tags = {
#     Terraform = "true"
#     Environment = "demo"
#   }
# }








# An AWS VPC
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc

resource "aws_vpc" "Terra-VPC" {

  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = join("", [var.VPC_NAME,"-",var.AWS_REGION])
  }
}


# NC2 Public Subnet
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet

resource "aws_subnet" "Terra-Public-Subnet" {
  vpc_id                  = aws_vpc.Terra-VPC.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true

  tags = {
    Name = join("", ["NC2-PublicSubnet-",var.AWS_REGION,"a"])
  }
}


# A private subnet for management traffic
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet 

resource "aws_subnet" "Terra-Private-Subnet-Mngt" {
  vpc_id                  = aws_vpc.Terra-VPC.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true

  tags = {
    Name = join("", ["NC2-PrivateMgntSubnet-",var.AWS_REGION,"a"])
  }
}


# One or more private subnets for user VM traffic
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet  

resource "aws_subnet" "Terra-Private-Subnet-UVM1" {
  vpc_id                  = aws_vpc.Terra-VPC.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-3a"
  map_public_ip_on_launch = true

  tags = {
    ## join function https://developer.hashicorp.com/terraform/language/functions/join
    Name = join("", ["NC2-PrivateSubnet-UVM1-",var.AWS_REGION,"a"])
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

# Elastic IP resource (EIP)
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

  route {
     # since this is exactly the route AWS will create, the route will be adopted
    cidr_block = "10.0.1.0/24"
    gateway_id = "local" # local route
  }

  tags = {
    Name = "NC2-Route-Table-Public"
  }
}



# Route Table for Private Subnet(s)
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
# this is the route table for the private subnets, to go to on-premises network or Internet

resource "aws_route_table" "Terra-Private-Route-Table" {
  vpc_id = aws_vpc.Terra-VPC.id

  # route {
  #   cidr_block = "0.0.0.0/24"
  #   gateway_id = aws_internet_gateway.example.id
  # }

  route {
    cidr_block = "10.0.2.0/24"
    gateway_id = "local" # local route
  }

  route {
    cidr_block = "10.0.3.0/24"
    gateway_id = "local" # local route
  }

  tags = {
    Name = "NC2-Route-Table-Private"
  }
}


# AWS Security Group for Public Subnet



# AWS Security Group for Private Subnets







### If there is a Web proxy configured #################

# VPC Endpoint for S3
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint
# resource "aws_vpc_endpoint" "s3" {
#   vpc_id       = aws_vpc.main.id
#   service_name = "com.amazonaws.us-west-2.s3"

#   tags = {
#     Environment = "test"
#   }
# }

# VPC Endpoint for EC2
# cf. https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint
# resource "aws_vpc_endpoint" "ec2" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.us-west-2.ec2"
#   vpc_endpoint_type = "Interface"
#   security_group_ids = [
#     aws_security_group.sg1.id,
#   ]
#   private_dns_enabled = true
# }

###################################################################



#### For Cluster Protect #####

# Two new AWS S3 buckets with Nutanix IAM role if you want to use 
# the Cluster Protect feature to protect Prism Central, UVM, and volume groups data.
# S3-Bucket
# cf. https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest 













# module "app_security_group" {
#   source  = "terraform-aws-modules/security-group/aws//modules/web"
#   version = "4.17.0"

#   name        = "web-sg-project-alpha-dev"
#   description = "Security group for web-servers with HTTP ports open within VPC"
#   vpc_id      = module.vpc.vpc_id

#   ingress_cidr_blocks = module.vpc.public_subnets_cidr_blocks

#   tags = {
#     project     = "project-alpha",
#     environment = "dev"
#   }
# }

# resource "random_string" "lb_id" {
#   length  = 3
#   special = false
# }


# module "ec2_instances" {
#   source = "./modules/aws-instance"

#   depends_on = [module.vpc]

#   instance_count     = 2
#   instance_type      = "t2.micro"
#   subnet_ids         = module.vpc.private_subnets[*]
#   security_group_ids = [module.app_security_group.security_group_id]

#   tags = {
#     project     = "project-alpha",
#     environment = "dev"
#   }
# }
