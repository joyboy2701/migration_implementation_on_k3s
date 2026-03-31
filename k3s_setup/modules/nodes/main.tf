data "template_file" "master_userdata" {
  template = file("${path.module}/userdata/master.sh")
  vars = {
    region = var.region
  }
}
data "template_file" "worker_userdata" {
  template = file("${path.module}/userdata/worker.sh")
  vars = {
    region = var.region
  }
}

resource "aws_security_group" "k3s_master" {
  name        = "${var.k3s_sg_name}-master"
  description = "Security group for K3s master nodes"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.master_ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.k3s_sg_name}-master"
  }
}
resource "aws_security_group" "k3s_worker" {
  name        = "${var.k3s_sg_name}-worker"
  description = "Security group for K3s worker nodes"
  vpc_id      = var.vpc_id

  # Allow worker → master API access
  dynamic "ingress" {
    for_each = var.worker_ingress_ports
    content {
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.k3s_master.id]
    }
  }
   ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.k3s_sg_name}-worker"
  }
}

resource "aws_instance" "k3s_master" {
  ami                    = var.ami_id
  instance_type          = var.k3s_master_instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.k3s_master.id]
  iam_instance_profile   = var.iam_instance_profile_master
  user_data              = data.template_file.master_userdata.rendered

  tags = merge(var.tags, {
    Name = var.k3s_master_name
     "kubernetes.io/cluster/k3s-cluster" = "owned"
  })
}
resource "aws_instance" "k3s_workers" {
  count                  = var.worker_count
  ami                    = var.ami_id
  instance_type          = var.k3s_worker_instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.k3s_worker.id]
  iam_instance_profile   = var.iam_instance_profile_worker
  user_data              = data.template_file.worker_userdata.rendered

  tags = merge(var.tags, {
    Name = "${var.k3s_worker_name_prefix}-${count.index + 1}"
     "kubernetes.io/cluster/k3s-cluster" = "owned"
  })
  depends_on = [ null_resource.wait_before_k8s_addons ]
}
resource "null_resource" "wait_before_k8s_addons" {
   depends_on = [ aws_instance.k3s_master ]

  provisioner "local-exec" {
    command = "echo 'Waiting 5 minutes before deploying addons...' && sleep 300"
  }
}
resource "null_resource" "wait_after_worker_creation" {

  provisioner "local-exec" {
    command = "echo 'Waiting 3 minutes before deploying addons...' && sleep 180"
  }
  depends_on = [ aws_instance.k3s_workers ]
}