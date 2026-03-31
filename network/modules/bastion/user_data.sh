#!/bin/bash
set -euxo pipefail

# Log everything
exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1

yum update -y
yum install -y git unzip curl

# -------------------------------
# Install AWS CLI v2
# -------------------------------
curl -L -o /tmp/awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
unzip -o /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --update
rm -rf /tmp/awscliv2.zip /tmp/aws

# Ensure PATH
echo 'export PATH=/usr/local/bin:$PATH' >> /home/ec2-user/.bashrc
export PATH=/usr/local/bin:$PATH

# -------------------------------
# Install Terraform (fixed version)
# -------------------------------
TERRAFORM_VERSION="1.6.5"
curl -L -o /tmp/terraform.zip \
  https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip -o /tmp/terraform.zip -d /usr/local/bin/
chmod +x /usr/local/bin/terraform
rm -f /tmp/terraform.zip

# -------------------------------
# Install kubectl (stable link)
# -------------------------------
KUBECTL_VERSION="$(curl -sL https://dl.k8s.io/release/stable.txt)"
curl -L -o /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x /tmp/kubectl
mv /tmp/kubectl /usr/local/bin/kubectl


# Clone the repository (replace with your actual repo URL)
GIT_REPO_URL="https://github.com/joyboy2701/migration_implementation_on_k3s.git"
CLONE_DIR="/home/ec2-user/"

echo "=== Cloning Git Repository ==="
git clone "$GIT_REPO_URL" "$CLONE_DIR/K3s"
cd /home/ec2-user/K3s/k3s_setup

# Initialize Terraform
echo "=== Initializing Terraform ==="
terraform init

# Optional: Plan before apply (recommended)
echo "=== Running Terraform Plan ==="
terraform plan -var-file="config/dev.tfvars"

set +e  # Disable exit on error

echo "=== Applying Terraform Configuration ==="
terraform apply -var-file="config/dev.tfvars" -auto-approve

set -e  # Re-enable exit on error for rest of script (if any)
# ---------- END OF NO-TERMINATE SECTION ----------

echo "=== User data completed ==="
