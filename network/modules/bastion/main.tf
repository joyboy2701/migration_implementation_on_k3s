resource "aws_security_group" "bastion_sg" {
  name   = var.bastion_sg_name
  vpc_id = var.vpc_id

  # Allow all inbound traffic
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress (use variable for allowed CIDRs)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.bastion_sg_egress_cidr
  }

  tags = {
    Name = var.bastion_sg_name
  }
}
# IAM Role for Bastion
resource "aws_iam_role" "bastion_role" {
  name = "${var.bastion_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = var.bastion_name
    Role = var.bastion_role
  }
}

# Custom IAM Policy from JSON file
resource "aws_iam_policy" "bastion_custom_policy" {
  name        = "${var.bastion_name}-custom-policy"
  description = "Custom policy for bastion host with Terraform and KOPS access"

  # Read policy from JSON file
  policy = file("${path.module}/bastion-policy.json")
}

# Attach custom policy to role
resource "aws_iam_role_policy_attachment" "bastion_custom" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = aws_iam_policy.bastion_custom_policy.arn
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${var.bastion_name}-profile"
  role = aws_iam_role.bastion_role.name
}
resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.bastion_profile.name
  associate_public_ip_address = true
  key_name                    = var.key_name

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name    = var.bastion_name
    Role    = var.bastion_role
    Cluster = var.bastion_cluster
  }
}
