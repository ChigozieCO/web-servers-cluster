provider "aws" {
  region = "us-east-1"
}
## The first step in creating an Auto Scaling Group (ASG) is to create a launch configuration, which specifies how to configure each EC2 Instance in the ASG.
## It's best to use a launch template but for this solution we would use a launch configuration.

resource "aws_launch_configuration" "launchconfig" {
  image_id = "ami-0a6b2839d44d781b2"
  instance_type = "t2.micro"
  vpc_zone_identifier = [data.aws_subnets.default.ids]

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
    EOF

    # Required when using a launch configuration with an auto scaling group.

    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "tf-asg" {
  launch_configuration = aws_launch_configuration.launchconfig.name

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "tf-asg-server2"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "server2-SG" {
  name = "server2-SG"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## We want terraform to pull the subnet id from AWS data source so we will add a data source to our configuration.

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}