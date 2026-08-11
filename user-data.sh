#! /bin/bash
sudo apt update -y
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install  -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


DB_ADDRESS=$(aws ssm get-parameter --name "/fitcubes/database/address" --region eu-north-1 --query Parameter.Value --output text --with-decryption)
DB_USERNAME=$(aws ssm get-parameter --name "/fitcubes/database/username" --region eu-north-1 --query Parameter.Value --output text --with-decryption)
DB_PASSWORD=$(aws ssm get-parameter --name "/fitcubes/database/password" --region eu-north-1 --query Parameter.Value --output text --with-decryption)
REDIS_ADDRESS=$(aws ssm get-parameter --name "/fitcubes/redis/address" --region eu-north-1 --query Parameter.Value --output text --with-decryption)

sudo docker run