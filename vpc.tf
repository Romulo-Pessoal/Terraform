data "aws_availability_zones" "available" {}

resource "aws_vpc" "VPC" {
  cidr_block           = var.vpcCIDRblock
  instance_tenancy     = var.instanceTenancy 
  enable_dns_support   = var.dnsSupport 
  enable_dns_hostnames = var.dnsHostNames
  tags = {
    Name = "VPC"
  }
} 
resource "aws_subnet" "Public_subnet" {
  count = "${length(data.aws_availability_zones.available.names)}"
  vpc_id                  = aws_vpc.VPC.id
  cidr_block              = "10.0.${10+count.index}.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = var.mapPublicIP 
  tags = {
   Name = "Public subnet"
  }
}
resource "aws_subnet" "Private_subnet_Front" {
  count = "${length(data.aws_availability_zones.available.names)}"
  vpc_id                  = aws_vpc.VPC.id
  cidr_block              = "10.0.${20+count.index}.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
 tags = {
   Name = "Private subnet (Front)"
  }
}
resource "aws_subnet" "Private_subnet_Back" {
  count = "${length(data.aws_availability_zones.available.names)}"
  vpc_id                  = aws_vpc.VPC.id
  cidr_block              = "10.0.${30+count.index}.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
 tags = {
   Name = "Private subnet (Back)"
  }
}
resource "aws_subnet" "Private_subnet_DB" {
  count = "${length(data.aws_availability_zones.available.names)}"
  vpc_id                  = aws_vpc.VPC.id
  cidr_block              = "10.0.${40+count.index}.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
 tags = {
   Name = "Private subnet (DB)"
  }
}
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for Bastion within VPC"
  vpc_id = aws_vpc.VPC.id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 8090
    to_port     = 8090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "bastion-sg"
  }
}
resource "aws_security_group" "frontend_sg" {
  name        = "frontend-sg"
  description = "Security group for Frontend within VPC"
  vpc_id = aws_vpc.VPC.id
  
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.external_lb_sg.id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
   tags = {
    Name = "Frontend-SG"
  }
}
resource "aws_security_group" "external_lb_sg" {
  name        = "external_lb-sg"
  description = "Security group for External LB within VPC"
  vpc_id = aws_vpc.VPC.id
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
   egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "external_lg-SG"
  }
}
resource "aws_security_group" "internal_lb_sg" {
  name        = "internal_lb-sg"
  description = "Security group for Internal LB within VPC"
  vpc_id = aws_vpc.VPC.id
  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "internal_lg-SG"
  }
}
resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  description = "Security group for Backend within VPC"
  vpc_id = aws_vpc.VPC.id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.internal_lb_sg.id]
  }
  ingress {
    description = "SSH"
    from_port   = 8090
    to_port     = 8090
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "Backend-SG"
  }
}
resource "aws_security_group" "DB_sg" {
  name        = "DB-sg"
  description = "Security group for DB within VPC"
  vpc_id = aws_vpc.VPC.id
  ingress {
    description = "Mysql"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }
  tags = {
    Name = "DB-SG"
  }
}
resource "aws_internet_gateway" "IGW" {
 vpc_id = aws_vpc.VPC.id
 tags = {
        Name = "Internet gateway"
  }
} 
resource "aws_eip" "eip" {
  vpc              = true
  depends_on = [aws_internet_gateway.IGW,]
}
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.Public_subnet[1].id
  depends_on = [aws_internet_gateway.IGW]
  tags = {
    Name = "gw NAT"
  }
}

resource "aws_route_table" "Public_RT" {
 vpc_id = aws_vpc.VPC.id
 tags = {
        Name = "Public Route table"
  }
} 
resource "aws_route_table" "Private_RT" {
 vpc_id = aws_vpc.VPC.id
 tags = {
        Name = "Private Route table"
  }
} 
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.Public_RT.id
  destination_cidr_block = var.publicdestCIDRblock
  gateway_id             = aws_internet_gateway.IGW.id
}

resource "aws_route" "private_internet_access" {
  route_table_id         = aws_route_table.Private_RT.id
  destination_cidr_block = var.publicdestCIDRblock
  gateway_id             = aws_nat_gateway.nat_gw.id
}
resource "aws_route_table_association" "Public_association" {
  count = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = aws_subnet.Public_subnet[count.index].id
  route_table_id = aws_route_table.Public_RT.id
}
resource "aws_route_table_association" "Private_Front_association" {
  count = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = aws_subnet.Private_subnet_Front[count.index].id
  route_table_id = aws_route_table.Private_RT.id
}
resource "aws_route_table_association" "Private_Back_association" {
  count = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = aws_subnet.Private_subnet_Back[count.index].id
  route_table_id = aws_route_table.Private_RT.id
}

