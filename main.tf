# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = "fast_food_clientes"
  cidr                 = "10.2.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.2.4.0/24", "10.2.5.0/24", "10.2.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_db_subnet_group" "fast_food_clientes" {
  name       = "fast_food_clientes"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "fast_food_clientes"
  }
}

resource "aws_security_group" "rds" {
  name   = "fast_food_clientes_rds"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fast_food_clientes_rds"
  }
}

resource "aws_db_parameter_group" "fast_food_clientes" {
  name   = "fast-food-clientes-parameter-group"
  family = "postgres15"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }
}

resource "aws_db_instance" "fast_food_clientes" {
  identifier             = "fast-food-clientes-db"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "15.3"
  username               = var.db_user
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.fast_food_clientes.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.fast_food_clientes.name
  publicly_accessible    = true
  skip_final_snapshot    = true
  apply_immediately      = true
}


provider "postgresql" {
  scheme   = "postgres"
  host     = aws_db_instance.fast_food_clientes.address
  port     = var.db_port
  username = var.db_user
  password = var.db_password
}

resource "postgresql_database" "fast_food_clientes" {
  name              = var.db_name
  owner             = var.db_user
  connection_limit  = -1
  allow_connections = true
}
