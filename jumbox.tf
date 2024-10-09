

resource "aws_instance" "Terra-Jumbox-Windows-Server" {
    # to get latest Windows Server AMI ID, visit https://aws.amazon.com/windows/ and click on "Launch instance"
    # aws ec2 describe-images --region eu-central-1 --owners amazon --filters "Name=name,Values=Windows_Server-2022-English-Full-Base-*" "Name=state,Values=available" --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" --output text
    ami           = "ami-01647a9d15b15e0af"        # Change to a valid Windows Server AMI ID for your region
    instance_type = "t3.medium"                    # t3.medium has 8 GB of RAM

    subnet_id = aws_subnet.Terra-Private-Subnet-Jumpbox.id

    tags = {
        Name = "WindowsServerJumbox-NC2"
    }

    key_name = var.KEY_PAIR_NAME

    # user_data = <<-EOF
    #                         <powershell>
    #                         # Add any custom PowerShell script you want to run on startup
    #                         </powershell>
    #                         EOF
}

resource "aws_security_group" "Terra-Jumbox-sg" {
    name        = "Jumbox-windows_sg"
    description = "Allow RDP traffic to Jumpbox"
    vpc_id      = aws_vpc.Terra-VPC.id

    ingress {
        from_port   = 3389
        to_port     = 3389
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Adjust CIDR block as needed for security
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_network_interface_sg_attachment" "Terra-sg-attachment" {
    security_group_id    = aws_security_group.Terra-Jumbox-sg.id
    network_interface_id = aws_instance.Terra-Jumbox-Windows-Server.primary_network_interface_id
}




# Create a Network Load Balancer (NLB)
resource "aws_lb" "Terra-NLB-Jumbox" {
  name               = "NLB-Jumbox"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.Terra-Public-Subnet.id]
  security_groups    = [aws_security_group.Terra-Jumbox-sg.id]

  tags = {
    Name = "NLB-Jumbox"
  }
}

# Create a Target Group for the EC2 instance
resource "aws_lb_target_group" "Terra-LB-Target-Group-Jumbox" {
  name        = "rdp-target-group"
  port        = 3389
  protocol    = "TCP"
  vpc_id      = aws_vpc.Terra-VPC.id
  target_type = "instance"
  health_check {
    protocol = "TCP"
  }
}

# Attach the EC2 instance to the Target Group
resource "aws_lb_target_group_attachment" "Terra-Target-Group-Attachment-jumbox" {
  target_group_arn = aws_lb_target_group.Terra-LB-Target-Group-Jumbox.arn
  target_id        = aws_instance.Terra-Jumbox-Windows-Server.id
  port             = 3389
}

# Create a Listener for the NLB to forward RDP traffic
resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.Terra-NLB-Jumbox.arn
  port              = 3389
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Terra-LB-Target-Group-Jumbox.arn
  }
}




output "Jumbox-IP" {
  value = aws_lb.Terra-NLB-Jumbox.dns_name
}