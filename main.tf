provider "aws" {
  region = "us-east-1"
}
## The first step in creating an Auto Scaling Group (ASG) is to create a launch configuration, which specifies how to configure each EC2 Instance in the ASG.
## It's best to use a launch template but for this solution we would use a launch configuration.

resource "aws_launch_configuration" "launchconfig" {
  image_id        = "ami-0a6b2839d44d781b2"
  instance_type   = "t2.micro"
  security_groups = [aws_security_groups.server2-SG.id]

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
  vpc_zone_identifier  = [data.aws_subnets.default.ids]

  target_group_arns = [aws_lb_target_group.alb-TG.arn]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "tf-asg-server2"
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
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

## Create a load balancer

resource "aws_lb" "server2-lb" {
  name               = "tf-server2-lb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb-SG.id]
}

## Define a listener for the ALB 

resource "aws_lb_listener" "lb-lsnr" {
  load_balancer_arn = aws_lb.server2-lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404

    }
  }
}

# Create a target group for the auto scaling group

resource "aws_lb_target_group" "alb-TG" {
  name     = tf-alb-TG
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

## Time to tie all these pieces together by creating listener rules

resource "aws_lb_listener_rule" "lb-lsnr-rule" {
  listener_arn = aws_lb_listener.lb-lsnr.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-TG.arn
  }
}
resource "aws_security_group" "alb-SG" {
  name = "tf-alb-SG"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}