# Configure the provider, region and your access/secret keys
provider "aws" {
  region     = var.region
  access_key = var.accessKey
  secret_key = var.secretKey
}


#Create a S3 Bucket

resource "aws_s3_bucket" "bestseller-bucket" {
  bucket = var.bucket
  acl    = var.acl

  tags = {
    Name        = "${var.bucketName}"
    Environment = "${var.environment}"
  }
}

#Creating a Virtual Network
resource "aws_vpc" "bestseller-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "development"
  }
}

#Creating a subnet
resource "aws_subnet" "subnet-bestseller_a" {
  vpc_id            = aws_vpc.bestseller-vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "dev-subnet-1a"
  }
}

resource "aws_subnet" "subnet-bestseller_b" {
  vpc_id            = aws_vpc.bestseller-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "dev-subnet-1b"
  }
}

#Creating an internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.bestseller-vpc.id


}


#Creating a route table

resource "aws_route_table" "dev-route-table" {
  vpc_id = aws_vpc.bestseller-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id


  }
}




#Associate subnet to route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-bestseller_a.id
  route_table_id = aws_route_table.dev-route-table.id
}


resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet-bestseller_b.id
  route_table_id = aws_route_table.dev-route-table.id
}



#Create a security Group

resource "aws_security_group" "allow_web" {
  name        = "Allow_web_traffic"
  description = "Allow Web traffic"
  vpc_id      = aws_vpc.bestseller-vpc.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "allow_web"
  }
}




resource "aws_key_pair" "my_aws_key" {
  key_name   = "main-key"
  public_key = var.publicKey
}



# #Defining the instance to deploy and installation of Apache

resource "aws_launch_configuration" "web" {
  name_prefix   = "web-"
  image_id      = var.ami
  instance_type = "t2.micro"
  key_name      = "main-key"

  security_groups             = ["${aws_security_group.allow_web.id}"]
  associate_public_ip_address = true

  user_data = <<-EOF
                #!bin/bash
                sudo apt update -y
                sudo apt install stress
                sudo apt install apache2 -y
                sudo systemctl start apache2
                my_ip=`ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'`
                sudo bash -c 'echo Hello BESTSELLER Engineers, this is my IP: '$my_ip > /var/www/html/index.html               
                EOF

}


resource "aws_security_group" "elb_http" {
  name        = "elb_http"
  description = "Allow HTTP traffic to instances through Elastic Load Balancer, ssh"
  vpc_id      = aws_vpc.bestseller-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP through ELB Security group"
  }

}

resource "aws_elb" "web_elb" {
  name                      = "web-elb"
  security_groups           = ["${aws_security_group.elb_http.id}"]
  subnets                   = ["${aws_subnet.subnet-bestseller_a.id}", "${aws_subnet.subnet-bestseller_b.id}"]
  cross_zone_load_balancing = true
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:80/"
  }
  listener {
    instance_port     = "80"
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}


resource "aws_autoscaling_group" "web" {
  name     = "${aws_launch_configuration.web.name}-asg"
  min_size = 1
  max_size = 3

  health_check_type = "ELB"
  load_balancers    = ["${aws_elb.web_elb.id}"]

  launch_configuration = aws_launch_configuration.web.name

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  vpc_zone_identifier = ["${aws_subnet.subnet-bestseller_a.id}", "${aws_subnet.subnet-bestseller_b.id}"]



  tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }

}


resource "aws_autoscaling_policy" "web_policy_up" {
  name                   = "web_policy_up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name

}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name          = "web_cpu_alarm_up"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.web.name}"
  }

  alarm_description = "This mestric monitor EC2 instance CPU Utilizantion"
  alarm_actions     = ["${aws_autoscaling_policy.web_policy_up.arn}"]

}

resource "aws_autoscaling_policy" "web_policy_down" {
  name                   = "web_policy_down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name

}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
  alarm_name          = "web_cpu_alarm_down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "60"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.web.name}"
  }

  alarm_description = "This metric monitor EC2 instance CPU Utilizantion"
  alarm_actions     = ["${aws_autoscaling_policy.web_policy_down.arn}"]

}


