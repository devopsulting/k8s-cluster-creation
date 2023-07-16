

# create vpc
resource "aws_vpc" "vpc" {
  cidr_block           = var.VPC_CIDR
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_classiclink   = false

  # Enable/disable ClassicLink DNS Support for the VPC.
  enable_classiclink_dns_support = false

  # Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC.
  assign_generated_ipv6_cidr_block = false

  # A map of tags to assign to the resource.

  tags = {
    Name = "${var.PROJECT_NAME}-vpc"
  }
}

# create internet gateway and attach it to vpc
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.PROJECT_NAME}-igw"
  }
}



# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}

# create public subnet pub-sub-1
resource "aws_subnet" "pub-sub-1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.PUB_SUB_1_CIDR
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name                        = "pub-sub-1"
    "kubernetes.io/cluster/${var.PROJECT_NAME}" = "shared"
    "kubernetes.io/role/elb"    = 1

  }
}

# create public subnet pub-sub-2-b
resource "aws_subnet" "pub-sub-2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.PUB_SUB_2_CIDR
  availability_zone       = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name                        = "pub-sub-2"
    "kubernetes.io/cluster/${var.PROJECT_NAME}" = "shared"
    "kubernetes.io/role/elb"    = 1
  }
}

# create route table and add public route
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "Public-RT"
  }
}

# associate public subnet pub-sub-1 to "public route table"
resource "aws_route_table_association" "pub-sub-1_route_table_association" {
  subnet_id      = aws_subnet.pub-sub-1.id
  route_table_id = aws_route_table.public_route_table.id
}

# associate public subnet az2 to "public route table"
resource "aws_route_table_association" "pub-sub-2-b_route_table_association" {
  subnet_id      = aws_subnet.pub-sub-2.id
  route_table_id = aws_route_table.public_route_table.id
}




# create private app subnet pri-sub-1
resource "aws_subnet" "pri-sub-1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.PRI_SUB_1_CIDR
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name                              = "pri-sub-1"
    "kubernetes.io/cluster/${var.PROJECT_NAME}"       = "shared"
    "kubernetes.io/role/internal-elb" = 1
  }
}

# create private app pri-sub-2
resource "aws_subnet" "pri-sub-2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.PRI_SUB_2_CIDR
  availability_zone       = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name                              = "pri-sub-2"
    "kubernetes.io/cluster/${var.PROJECT_NAME}"       = "shared"
    "kubernetes.io/role/internal-elb" = 1
  }
}