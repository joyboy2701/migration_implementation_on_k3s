#!/bin/bash
sudo sed -i 's|us-east-2.ec2.archive.ubuntu.com|archive.ubuntu.com|g' /etc/apt/sources.list
sudo apt-get update
set -euxo pipefail

AWS_REGION="${region}"

# -------------------------------
# Update system and install dependencies
# -------------------------------
apt-get update -y
apt-get upgrade -y
apt-get install -y curl unzip jq

# -------------------------------
# Install AWS CLI v2
# -------------------------------
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# -------------------------------
# Get instance metadata using IMDSv2
# -------------------------------
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

echo "Instance ID: $INSTANCE_ID"
echo "Private IP: $PRIVATE_IP"
echo "AWS Region: $AWS_REGION"

# -------------------------------
# Wait for Master to finish setup and fetch join command from SSM
# -------------------------------
MAX_RETRIES=30
SLEEP_SECONDS=10
JOIN_CMD=""

for i in $(seq 1 $MAX_RETRIES); do
    echo "Attempt $i to fetch join command from SSM..."
    JOIN_CMD=$(aws ssm get-parameter \
        --name "/k3s/join-command" \
        --query "Parameter.Value" \
        --output text \
        --region "$AWS_REGION" 2>/dev/null || true)

    if [ -n "$JOIN_CMD" ] && [ "$JOIN_CMD" != "None" ]; then
        echo "Join command fetched successfully."
        break
    fi

    echo "Join command not found yet. Sleeping $SLEEP_SECONDS seconds..."
    sleep $SLEEP_SECONDS
done

if [ -z "$JOIN_CMD" ] || [ "$JOIN_CMD" = "None" ]; then
    echo "ERROR: Could not fetch join command from SSM after $MAX_RETRIES attempts."
    exit 1
fi

# -------------------------------
# Extract K3S_URL and K3S_TOKEN from join command
# -------------------------------
K3S_URL=$(echo "$JOIN_CMD" | grep -oP 'K3S_URL=\K[^ ]+' | head -1)
K3S_TOKEN=$(echo "$JOIN_CMD" | grep -oP 'K3S_TOKEN=\K[^ ]+' | head -1)

if [ -z "$K3S_URL" ] || [ -z "$K3S_TOKEN" ]; then
    echo "ERROR: Could not extract K3S_URL or K3S_TOKEN from join command"
    exit 1
fi

echo "K3S_URL: $K3S_URL"
echo "K3S_TOKEN: $${K3S_TOKEN:0:10}... (truncated)"

# -------------------------------
# Install K3s agent with AWS-friendly configuration
# -------------------------------
# This is the key part - setting node-name to INSTANCE_ID and provider-id correctly
curl -sfL https://get.k3s.io | K3S_URL="$K3S_URL" K3S_TOKEN="$K3S_TOKEN" sh -s - agent --node-name="$INSTANCE_ID" --node-ip="$PRIVATE_IP" --kubelet-arg="provider-id=aws:///$${AWS_REGION}/$${INSTANCE_ID}" --resolv-conf=/etc/resolv.conf
# -------------------------------
# Enable and start k3s-agent service
# -------------------------------
systemctl enable k3s-agent
systemctl start k3s-agent

# -------------------------------
# Wait for node to register and verify
# -------------------------------
sleep 30


echo "=========================================="
echo "K3s Worker joined successfully!"
echo "Node name: $INSTANCE_ID"
echo "Provider ID: aws:///$AWS_REGION/$INSTANCE_ID"
echo "AWS Load Balancer Controller will now auto-register this node"
echo "=========================================="