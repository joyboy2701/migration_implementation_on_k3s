resource "aws_iam_role" "node_ssm_role" {
  name = var.node_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy" "node_limited_ssm_policy" {
  name = "${var.node_role_name}-limited-policy"
  role = aws_iam_role.node_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:PutParameter",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:DescribeListenerAttributes",
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach AmazonSSMManagedInstanceCore for full SSM connectivity
resource "aws_iam_role_policy_attachment" "node_ssm_core_attachment" {
  role       = aws_iam_role.node_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "node_ssm_core_attachment_ec2_access" {
  role       = aws_iam_role.node_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}
resource "aws_iam_role_policy_attachment" "awslb_policy_attachment" {
  role       = aws_iam_role.node_ssm_role.name
  policy_arn = "arn:aws:iam::569023477847:policy/AWSLoadBalancerControllerIAMPolicy"
}
resource "aws_iam_instance_profile" "node_ssm_instance_profile" {
  name = var.node_profile_name
  role = aws_iam_role.node_ssm_role.name
}


resource "aws_iam_role" "worker_role" {
  name = "${var.node_role_name}-worker"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

# Only allow read access to Parameter Store for worker nodes
resource "aws_iam_role_policy" "worker_param_read_policy" {
  name = "${var.node_role_name}-worker-param-read"
  role = aws_iam_role.worker_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "worker_instance_profile" {
  name = "${var.node_profile_name}-worker"
  role = aws_iam_role.worker_role.name
}
resource "aws_iam_role_policy_attachment" "node_ssm_core_attachment_worker" {
  role       = aws_iam_role.worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "node_ssm_core_attachment_worker_ec2_access" {
  role       = aws_iam_role.worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}
resource "aws_iam_role_policy_attachment" "load_balancer_policy_attachment_worker" {
  role       = aws_iam_role.worker_role.name
  policy_arn = "arn:aws:iam::569023477847:policy/AWSLoadBalancerControllerIAMPolicy"
}