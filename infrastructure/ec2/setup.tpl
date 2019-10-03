#! /bin/bash
sudo yum update -y
sudo yum install htop -y
sudo amazon-linux-extras install docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -a -G docker ec2-user
sudo $(sudo aws ecr get-login --no-include-email --region ${region})
sudo docker pull ${repository_url}:latest
sudo docker run -d --name postgis-server \
    -e POSTGRES_PASSWORD='${postgres_password}' \
    -p 5432:5432 \
    ${repository_url}:latest
