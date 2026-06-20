#!/bin/bash
set -e

yum update -y

yum install -y docker

systemctl start docker
systemctl enable docker

usermod -aG docker ec2-user

mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

yum install -y git

echo "Backend setup complete."