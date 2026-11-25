
# RDS DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.database_name}-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.database_name}-subnet-group"
  }
}

# RDS Security Group
resource "aws_security_group" "main" {
  name        = "${var.database_name}-sg"
  description = "Allow PostgreSQL access from EKS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from EKS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.database_name}-sg"
  }
}

# PostgreSQL RDS Instance
resource "aws_db_instance" "main" {
  identifier = var.database_name

  engine         = "postgres"
  instance_class = var.database_instance_class

  allocated_storage = 20
  storage_type      = "gp3"

  storage_encrypted = true

  db_name  = var.initial_database_name
  username = var.database_username
  password = var.database_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.main.id]

  publicly_accessible = false
  multi_az             = false

  backup_retention_period = 1

  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name = var.database_name
  }
}
