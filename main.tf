provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "server2" {
  ami                    = "ami-0a6b2839d44d781b2"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.server2-SG.id]

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
    EOF

  user_data_replace_on_change = true

  tags {
    Name = tf-server2
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