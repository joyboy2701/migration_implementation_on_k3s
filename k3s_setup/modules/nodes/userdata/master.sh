#!/bin/bash
sudo sed -i 's|us-east-2.ec2.archive.ubuntu.com|archive.ubuntu.com|g' /etc/apt/sources.list
sudo apt-get update
set -euxo pipefail

AWS_REGION="${region}" 
# -------------------------------
# Update system and install curl
# -------------------------------
apt-get update -y
apt-get upgrade -y
apt-get install -y curl unzip


# Get instance metadata using IMDSv2
# -------------------------------
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

echo "Instance ID: $INSTANCE_ID"
echo "Private IP: $PRIVATE_IP"
echo "AWS Region: $AWS_REGION"

# -------------------------------
# Install K3s (Server Mode - Master Node)
# -------------------------------
curl -sfL https://get.k3s.io | \
INSTALL_K3S_EXEC="server \
--write-kubeconfig-mode 644 \
--disable=traefik,servicelb \
--kubelet-arg=cloud-provider=external \
--kubelet-arg=provider-id=aws:///$${AWS_REGION}/$${INSTANCE_ID} \
--node-name=$${INSTANCE_ID} \
--node-ip=$${PRIVATE_IP}" \
sh -


# Enable K3s service
systemctl enable k3s

# Wait for node to be ready
sleep 20

# -------------------------------
# Save node token for workers
# -------------------------------
NODE_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
echo "$NODE_TOKEN" > /home/ubuntu/node-token
chown ubuntu:ubuntu /home/ubuntu/node-token

# -------------------------------
# Install AWS CLI v2
# -------------------------------
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp
/tmp/aws/install


# -------------------------------
# Get Master Private IP
# -------------------------------
MASTER_IP=$(hostname -I | awk '{print $1}')


aws ssm put-parameter \
  --name "/k3s/kubeconfig" \
  --value "$(sudo cat /etc/rancher/k3s/k3s.yaml)" \
  --type SecureString \
  --overwrite \
  --region "$AWS_REGION"  # default region if not set

# -------------------------------
# Store Join Command in Parameter Store
# -------------------------------
sleep 20
JOIN_COMMAND="curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$NODE_TOKEN sh -"

# Put the command in SSM Parameter Store
aws ssm put-parameter \
    --name "/k3s/join-command" \
    --value "$JOIN_COMMAND" \
    --type "String" \
    --overwrite \
    --region "$AWS_REGION"  # default region if not set

echo "K3s Master setup complete and join command stored in SSM"




