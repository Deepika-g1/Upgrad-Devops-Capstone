# Creating the VPC

resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "MyVpc" 
  }
}

#Creating the IGW

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "MyIgw" # Internet Gateway name
  }
}

# Find available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

#  Creating 2 Public Subnets in each AZ
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"  
  availability_zone = element
tags = {
    Name = "PublicSubnetA"
     "kubernetes.io/cluster/my-eks-201" = "shared"
    "kubernetes.io/roles/elb"        = "1"
    }
}
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"  
  availability_zone = element
tags = {
    Name = "PublicSubnetB"
     "kubernetes.io/cluster/my-eks-201" = "shared"
    "kubernetes.io/roles/elb"        = "1"
    }
}
# Creating an elastic IP
resource "aws_eip" "eip" {
  domain = "vpc"
}

#Creating the NGW

resource "aws_nat_gateway" "network_interface" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public.0.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "NAT" # NAT Gateway name
  }
}

# Creating 2 Private Subnets in each AZ
resource "aws_subnet" "private" {
 
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.3.0/24" 
  availability_zone = element
    Name = "PrivateSubnetA"
    "kubernetes.io/cluster/my-eks-201" = "shared"
    "kubernetes.io/roles/elb"        = "1"
    }
resource "aws_subnet" "private" {
 
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.4.0/24" 
  availability_zone = element
    Name = "PrivateSubnetB"
    "kubernetes.io/cluster/my-eks-201" = "shared"
    "kubernetes.io/roles/elb"        = "1"
    }
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
tags = {
    Name = "PublicRouteTable"
  }
}

# Associating public subnets to public route table
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

# Creating a Private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.network_interface.id
  }
tags = {
    Name = "PrivateRouteTable"
  }
}
# Associating private subnets to private route table
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private.id
}
