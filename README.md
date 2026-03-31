# 🚀 K3s Cluster on AWS using Terraform (Modular + Production-Ready)

This project provisions a **fully functional, production-style K3s Kubernetes cluster on AWS** using Terraform.

It is split into two major layers:

- **network/** → AWS infrastructure foundation (VPC, subnets, bastion, routing)
- **k3s_setup/** → Kubernetes cluster bootstrap, addons, and application deployments

It also includes **end-to-end traffic routing design** (public → private workloads) using **Ingress NGINX + Cloud Controller Manager (CCM)**.

---

# 📐 Architecture Overview

## 🧱 Infrastructure Layer (network/)
Responsible for building the AWS foundation:

- Custom VPC
- Public & Private Subnets
- Internet Gateway + NAT Gateway
- Route Tables
- Bastion Host (for controlled access)
- Security Groups
- Shared networking for all workloads

## ☸️ Kubernetes Layer (k3s_setup/)
Responsible for cluster and platform provisioning:

- K3s Master Node (in private or controlled subnet)
- Worker Nodes (private subnet, scalable)
- AWS IAM integration for nodes
- Helm provider for Kubernetes add-ons
- Kubectl provider for direct manifests
- AWS Cloud Controller Manager (CCM)
- Ingress NGINX Controller
- Test application deployment (via Helm / kubectl)

---

# 🌐 Traffic Flow Architecture

Internet → Public Domain →  AWS Load Balancer (ALB) → Internal Ingress Load Balancer(NLB)  → Kubernetes Services → Pods

Bastion Host → K3s Cluster (kubectl / helm operations inside VPC)

Key principles:
- No public access to worker nodes
- Only ingress exposed externally
- Bastion used for controlled operations
- CCM manages AWS integration
- Ingress handles internal routing

---

# 📁 Project Structure


```bash
.
├── k3s_setup
│   ├── config
│   │   └── dev.tfvars
│   ├── data.tf
│   ├── deployment.tf
│   ├── main.tf
│   ├── modules
│   │   ├── helm
│   │   │   ├── main.tf
│   │   │   ├── values_ccm.yaml
│   │   │   ├── values.yaml
│   │   │   └── variables.tf
│   │   ├── iam
│   │   │   ├── main.tf
│   │   │   ├── output.tf
│   │   │   └── variable.tf
│   │   ├── load-balancer
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   └── variables.tf
│   │   ├── nodes
│   │   │   ├── main.tf
│   │   │   ├── outputs.tf
│   │   │   ├── userdata
│   │   │   │   ├── master.sh
│   │   │   │   └── worker.sh
│   │       └── variables.tf
│   │  
│   ├── outputs.tf
│   ├── provider.tf
│   ├── README.md
│   └── variables.tf
└── network
    ├── config
    │   └── dev.tfvars
    ├── main.tf
    ├── modules
    │   ├── bastion
    │   │   ├── bastion-policy.json
    │   │   ├── main.tf
    │   │   ├── output.tf
    │   │   ├── user_data.sh
    │   │   └── variables.tf
    │   └── vpc
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    ├── output.tf
    ├── provider.tf
    └── variable.tf
```


# 🧩 Network Module

- VPC creation
- Public/private subnet segmentation
- NAT Gateway for private routing
- Bastion host for secure access
- Security groups for controlled traffic

---

# ☸️ K3s Setup Module

- K3s cluster bootstrap
- Scalable worker nodes
- IAM instance profiles
- Helm deployments
- Kubectl-based manifests
- AWS CCM integration
- Ingress NGINX controller

---

# 🚀 Bastion-Based Automation

All Kubernetes operations run via Bastion:

- Terraform triggers user-data scripts
- Bastion executes:
  - kubectl apply
  - helm install/upgrade
  - cluster bootstrap tasks
- Bastion has VPC-level access to cluster

---

# 🔐 Security Model

- No SSH to Kubernetes nodes
- No public worker nodes
- Bastion is the only controlled entry point
- IAM-based AWS access
- Private API server design

---

# 🌍 Ingress Traffic Flow

app.example.com → AWS Load Balancer → Ingress NGINX → Service → Pod

---

# ⚙️ Deployment
cd network
terraform init
terraform plan -var-file="config/dev.tfvars"s
terraform apply -var-file="config/dev.tfvars"

---

# 📦 Features

✔ Modular AWS infrastructure  
✔ Private K3s cluster  
✔ Bastion-based automation  
✔ Helm + Kubectl provisioning  
✔ AWS CCM integration  
✔ Ingress-based routing  
✔ Production-style architecture  
