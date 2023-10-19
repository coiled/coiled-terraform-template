

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "coiled-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "coiled-internet-gateway"
  }
}

resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  route {
    cidr_block = var.vpc_cidr
    gateway_id = "local"
  }

  tags = {
    Name = "coiled-default-route-table"
  }
}

resource "aws_subnet" "public_subnet" {
  for_each                = { for idx, az_name in data.aws_availability_zones.available.names : idx => az_name }
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, each.key)
  availability_zone       = each.value
  map_public_ip_on_launch = true

  tags = {
    "Name" : "coiled-public-subnet-${each.value}"
  }
}

resource "aws_security_group" "cluster_security_group" {
  name        = "coiled-cluster-security-group"
  vpc_id      = aws_vpc.main.id
  description = "Security group for Coiled clusters. Allows outbound traffic to the internet, and internal traffic between nodes in the VPC."
  egress {
    # all internet
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    # other nodes in the VPC
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
}

resource "aws_security_group" "scheduler_security_group" {
  name        = "coiled-scheduler-security-group"
  vpc_id      = aws_vpc.main.id
  description = "Security group for the dask scheduler in a Coiled cluster. Allows outbound traffic to the internet, internal traffic between nodes in the VPC, and inbound traffic to the dask dashboard + scheduler ports."
  egress {
    # all internet
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    # other nodes in the VPC
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
  ingress {
    # dask dashboard
    from_port   = 8787
    to_port     = 8787
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # dask scheduler
    from_port   = 8786
    to_port     = 8786
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # ssh (required for coiled run)
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # jupyter (required for coiled notebooks)
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # jupyter https
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
