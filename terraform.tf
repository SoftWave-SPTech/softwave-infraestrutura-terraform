resource "aws_vpc" "main" {
cidr_block = var.vpc_cidr
enable_dns_hostnames = true
enable_dns_support = true
tags = merge({ Name = "main-vpc" }, var.tags)
}


# Public subnets
resource "aws_subnet" "public" {
count = length(var.public_subnets)
vpc_id = aws_vpc.main.id
cidr_block = var.public_subnets[count.index]
map_public_ip_on_launch = true
tags = merge({ Name = "public-subnet-${count.index + 1}" }, var.tags)
}


# Private subnets
resource "aws_subnet" "private" {
count = length(var.private_subnets)
vpc_id = aws_vpc.main.id
cidr_block = var.private_subnets[count.index]
tags = merge({ Name = "private-subnet-${count.index + 1}" }, var.tags)
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
vpc_id = aws_vpc.main.id
tags = merge({ Name = "main-igw" }, var.tags)
}


# Public route table
resource "aws_route_table" "public" {
vpc_id = aws_vpc.main.id


route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.igw.id
}


tags = merge({ Name = "public-rt" }, var.tags)
}


resource "aws_route_table_association" "public_assoc" {
count = length(aws_subnet.public)
subnet_id = aws_subnet.public[count.index].id
route_table_id = aws_route_table.public.id
}


# Elastic IP for NAT
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.igw]
}


# NAT Gateway (na primeira public subnet)
resource "aws_nat_gateway" "natgw" {
allocation_id = aws_eip.nat_eip.id
subnet_id = aws_subnet.public[0].id
tags = merge({ Name = "natgw" }, var.tags)
depends_on = [aws_internet_gateway.igw]
}


# Private route table -> NAT
resource "aws_route_table" "private" {
vpc_id = aws_vpc.main.id


route {
cidr_block = "0.0.0.0/0"
nat_gateway_id = aws_nat_gateway.natgw.id
}


tags = merge({ Name = "private-rt" }, var.tags)
}


resource "aws_route_table_association" "private_assoc" {
count = length(aws_subnet.private)
subnet_id = aws_subnet.private[count.index].id
route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "sg_public_frontend" {
  name = "public-frontend-sg"
  vpc_id = aws_vpc.main.id


ingress {
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
description = "Allow HTTP"
}

ingress {
from_port = 443
to_port = 443
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
description = "Allow HTTPS"
}


ingress {
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
description = "Allow SSH"
}


egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
description = "Allow all outbound traffic"
}


tags = merge({ Name = "public-frontend-sg" }, var.tags)
}

resource "aws_security_group" "sg_private_backend" {
  name   = "private-backend-sg"
  vpc_id = aws_vpc.main.id

  # API Principal (8080)
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_public_frontend.id]
    description     = "Allow API Principal from Frontend"
  }

  # API Documentos e Fotos (8081)
  ingress {
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_public_frontend.id]
    description     = "Allow API Docs/Fotos from Frontend"
  }

  # API Gemini (8082)
  ingress {
    from_port       = 8082
    to_port         = 8082
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_public_frontend.id]
    description     = "Allow API Gemini from Frontend"
  }

  # API Autenticação Email (8083)
  ingress {
    from_port       = 8083
    to_port         = 8083
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_public_frontend.id]
    description     = "Allow API Autenticacao from Frontend"
  }

  # API Info Simples (8084)
  ingress {
    from_port       = 8084
    to_port         = 8084
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_public_frontend.id]
    description     = "Allow API Info Simples from Frontend"
  }

  # SSH opcional vindo apenas do frontend (bastion improvisado)
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_public_frontend.id]
    description     = "SSH allowed only from Frontend"
  }

  # Backend pode sair para qualquer lugar (update, API externas, NAT Gateway)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ Name = "private-backend-sg" }, var.tags)
}



# EC2 Frontend (2 instâncias) - em subnets públicas
resource "aws_instance" "frontend" {
count = 2
ami = var.ami_id
instance_type = var.instance_type
subnet_id = aws_subnet.public[count.index].id
key_name = aws_key_pair.generated_key.key_name


vpc_security_group_ids = [aws_security_group.sg_public_frontend.id]


tags = merge({ Name = "frontend-softwave-${count.index + 1}" }, var.tags)
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = file("id_softwave.pem.pub")
}

# EC2 Backend (2 instâncias) - em subnets privadas, sem IP público
resource "aws_instance" "backend" {
count = 2
ami = var.ami_id
instance_type = var.instance_type
subnet_id = aws_subnet.private[count.index].id
key_name = aws_key_pair.generated_key.key_name
associate_public_ip_address = false


vpc_security_group_ids = [aws_security_group.sg_private_backend.id]


tags = merge({ Name = "backend-softwave-${count.index + 1}" }, var.tags)
}

# ACL para subnets públicas
resource "aws_network_acl" "public_acl" {
  vpc_id = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id
  tags = merge({ Name = "public-acl" }, var.tags)
}

resource "aws_network_acl_rule" "public_inbound" {
  network_acl_id = aws_network_acl.public_acl.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "public_outbound" {
  network_acl_id = aws_network_acl.public_acl.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# ACL para subnets privadas
resource "aws_network_acl" "private_acl" {
  vpc_id = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id
  tags = merge({ Name = "private-acl" }, var.tags)
}

resource "aws_network_acl_rule" "private_inbound" {
  network_acl_id = aws_network_acl.private_acl.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "10.0.0.0/16"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "private_outbound" {
  network_acl_id = aws_network_acl.private_acl.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}