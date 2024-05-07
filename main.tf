terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region_name
}

resource "aws_iam_role" "my_role" {
  name = "my_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "iam ec2 role"
  }
}

resource "aws_vpc" "cstomVPC" {
  cidr_block = var.vpc_cidr
}



resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.cstomVPC.id

  tags = {
    Name = "igw"
  }
}
resource "aws_route_table" "publicRT" {
  vpc_id = aws_vpc.cstomVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    name = "publicRT"
  }

}

resource "aws_subnet" "custom_public_subnet1" {
  vpc_id                  = aws_vpc.cstomVPC.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az1

  tags = {
    Name = "publicSubnet1"
  }
}
resource "aws_route_table_association" "public_subnet_association1" {
  subnet_id      = aws_subnet.custom_public_subnet1.id
  route_table_id = aws_route_table.publicRT.id
}

resource "aws_subnet" "custom_public_subnet2" {
  vpc_id                  = aws_vpc.cstomVPC.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az2

  tags = {
    Name = "publicSubnet2"
  }
}
resource "aws_route_table_association" "public_subnet_association2" {
  subnet_id      = aws_subnet.custom_public_subnet2.id
  route_table_id = aws_route_table.publicRT.id
}


resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.cstomVPC.id

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "allow_tls1_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

}


resource "aws_instance" "app_server1" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.custom_public_subnet1.id
  security_groups = [aws_security_group.allow_tls.id]



  tags = {
    Name = "leonelleterraform1"
  }
}

resource "aws_instance" "app_server2" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.custom_public_subnet2.id
  security_groups = [aws_security_group.allow_tls.id]



  tags = {
    Name = "leonelleterraform2"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.cstomVPC.id

  tags = {
    Name = "alb_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls2_ipv4" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic1_ipv4" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

}

resource "aws_s3_bucket" "sbucket" {
  bucket = "s3buke"
}

resource "aws_s3_bucket_ownership_controls" "sbucket" {
  bucket = aws_s3_bucket.sbucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "s3bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.sbucket]

  bucket = aws_s3_bucket.sbucket.id
  acl    = "private"
}

resource "aws_lb_target_group" "alb-tg" {
  name        = "tf-lb-alb-tg"
  target_type = "alb"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.cstomVPC.id
}

resource "aws_lb" "web_alb" {
  name               = "leoapp-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.custom_public_subnet1.id, aws_subnet.custom_public_subnet2.id]

  tags = {
    Environment = "lab"
  }
}

resource "aws_subnet" "custom_private_subnet1" {
  vpc_id                  = aws_vpc.cstomVPC.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az1

  tags = {
    Name = "privateSubnet1"
  }
}
resource "aws_route_table_association" "private_subnet_association1" {
  subnet_id      = aws_subnet.custom_private_subnet1.id
  route_table_id = aws_route_table.publicRT.id
}

resource "aws_subnet" "custom_private_subnet2" {
  vpc_id                  = aws_vpc.cstomVPC.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.az2

  tags = {
    Name = "privateSubnet2"
  }
}
resource "aws_route_table_association" "private_subnet_association2" {
  subnet_id      = aws_subnet.custom_private_subnet2.id
  route_table_id = aws_route_table.publicRT.id
}




resource "aws_db_subnet_group" "rds_group" {
  name       = "mysql_subg"
  subnet_ids = [aws_subnet.custom_private_subnet1.id, aws_subnet.custom_private_subnet2.id]

  tags = {
    Name = "My DB subnet group"
  }
}


resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.cstomVPC.id

  tags = {
    Name = "rds_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls3_ipv4" {
  security_group_id = aws_security_group.rds_sg.id
  cidr_ipv4         = "10.20.0.0/20"
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic2_ipv4" {
  security_group_id = aws_security_group.rds_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

}





resource "aws_db_instance" "leonelledb" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  db_name              = "db_leonelle"
  username             = "myuser"
  password             = "mypassword"
  db_subnet_group_name = aws_db_subnet_group.rds_group.name

}

resource "aws_launch_template" "my_AS_template" {
  name_prefix   = "my-AS-template"
  image_id      = var.ami_id
  instance_type = "t2.micro"
  # Other configuration settings go here
}


resource "aws_autoscaling_group" "autoScaling" {
  availability_zones = ["ap-southeast-2a"]
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2

  # Specify either launch_configuration, launch_template, or mixed_instances_policy
  launch_template {
    id      = aws_launch_template.my_AS_template.id
    version = "$Latest" # Use the latest version of the launch template
  }
}



resource "aws_iam_role_policy" "s3_full_access" {
  name = "s3fullaccess"
  role = aws_iam_role.my_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:*",
        Resource = "*",
      },
    ],
  })
}

resource "aws_launch_configuration" "as_conf" {
  name_prefix   = "terraform-lc-example-"
  image_id      = var.ami_id
  instance_type = "t2.micro"

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_placement_group" "test" {
  name     = "test"
  strategy = "cluster"
}

resource "aws_autoscaling_group" "bar" {
  name                      = "terraform-asg-example"
  launch_configuration      = aws_launch_configuration.as_conf.name
  min_size                  = 2
  max_size                  = 5
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 4
  force_delete              = true
  placement_group           = aws_placement_group.test.id
  vpc_zone_identifier       = [aws_subnet.custom_public_subnet1.id, aws_subnet.custom_public_subnet2.id]

  lifecycle {
    create_before_destroy = true
  }
}

