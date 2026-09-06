# The VPC - a private network with NO internet gateway.
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.name}-vpc" }
}

# App subnets - one per AZ - for EC2 / ASG servers
resource "aws_subnet" "app" {
  count = length(var.app_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.app_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.name}-app-${count.index + 1}"
    Tier = "app"
  }
}

# DB subnets - one per AZ - for RDS
resource "aws_subnet" "db" {
  count = length(var.db_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.db_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.name}-db-${count.index + 1}"
    Tier = "db"
  }
}

# One route table for everything. It only has the automatic "local" route,
# so traffic can move inside the VPC but cannot leave it.
resource "aws_route_table" "internal" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.name}-internal-rt" }
}

resource "aws_route_table_association" "app" {
  count = length(aws_subnet.app)

  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.internal.id
}

resource "aws_route_table_association" "db" {
  count = length(aws_subnet.db)

  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.internal.id
}

# ---------- VPC Endpoints: private side-doors to AWS services ----------

# Security group for the interface endpoints: allow HTTPS from inside the VPC
resource "aws_security_group" "endpoints" {
  name        = "${var.name}-vpce-sg"
  description = "HTTPS from the VPC to AWS service endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-vpce-sg" }
}

# S3 gateway endpoint (free). Amazon Linux package repos live in S3,
# so this is what lets `dnf install` work with no internet.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.internal.id]

  tags = { Name = "${var.name}-s3-endpoint" }
}

# Interface endpoints (one network card per AZ inside the app subnets)
resource "aws_vpc_endpoint" "interface" {
  for_each = toset(var.interface_endpoints)

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.app[*].id
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = { Name = "${var.name}-${each.key}-endpoint" }
}
