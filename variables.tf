
variable "VPC_NAME" {
  description = "The name of the VPC"
  default     = "NC2-VPC"
}

variable "AWS_REGION" {
  description = "The AWS region to deploy to"
  default     = "us-west-2"     # eu-west-3	= Paris Region
}

# Key Pair Name for EC2 Jumbox instances
# Must be created in the AWS region where the instances will be deployed
variable "KEY_PAIR_NAME" {
  description = "The name of the key pair to use for SSH access"
}


# Define the CIDR blocks for the VPC and subnets.
# The VPC_CIDR block must be a valid private (RFC 1918) block.
# CIDR requirements: /16 and /25 including both
variable "VPC_CIDR" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

# CIDR requirements: /16 and /23 including both
# a /28 CIDR should be enough. It's the value used if VPC is created through NC2 portal wizard
variable "PUBLIC_SUBNET_CIDR" {
  description = "The CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}

# A private subnet for cluster management traffic
variable "PRIVATE_SUBNET_MGMT_CIDR" {
  description = "The CIDR block for the private management subnet where EC2.metal instances will be deployed"
  default     = "10.0.2.0/24"
}

# The user VM private subnet CIDR can have a netmask between /16 and /25 as allowed
# by the size of the VPC CIDR
variable "PRIVATE_SUBNET_UVM1_CIDR" {
  description = "The CIDR block for the UVM subnet where Nutanix VM are deployed"
  default     = "10.0.3.0/24" 
}

# The Prism Central private subnet CIDR can have a netmask between /16 and /25 as allowed
variable "PRIVATE_SUBNET_PC" {
  description = "The CIDR block for the PC subnet where the Prism Central VM is deployed"
  default     = "10.0.4.0/24"
}

# Subnet used for Flow Virtual Networking (FVN)
# CIDR requirements: /16 and /25 including both
variable "PRIVATE_SUBNET_FVN" {
  description = "The CIDR block for the FVN subnet"
  default     = "10.0.5.0/24"
}

# Subnet for Jumpbox VMs
variable "PRIVATE_SUBNET_JUMPBOX" {
  description = "The CIDR block for the Jumpbox subnet"
  default     = "10.0.6.0/24"  
}

# Windows Server 2022 English Full Base AMI ID for Jumbox VM
# to get latest Windows Server AMI ID, visit https://aws.amazon.com/windows/ and click on "Launch instance"
# aws ec2 describe-images --region eu-central-1 --owners amazon --filters "Name=name,Values=Windows_Server-2022-English-Full-Base-*" "Name=state,Values=available" --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" --output text
variable "WINDOWS_SERVER_2002_ENGLISHFULLBASE_AMI_ID" {
  description = "The AMI ID for the Windows Server 2022 English Full Base image"
  default     = "ami-0b6f453078047c11b"
}