resource "aws_key_pair" "ec2" {
  key_name   = "${var.vpc_name}-ec2-key"
  public_key = file(var.public_key_path)
}

resource "aws_launch_template" "example" {
  name = "${var.vpc_name}-launch-template"

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 10
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  image_id = var.ami

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = var.instance_type

  key_name = aws_key_pair.ec2.key_name

  monitoring {
    enabled = true
  }

  update_default_version = true

  network_interfaces {
    associate_public_ip_address = true
  }

  vpc_security_group_ids = [aws_security_group.backend.id]


  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.vpc_name}-template"
    }
  }

  user_data = base64encode(<<-EOD
        #!/bin/bash
        sudo apt update -y
        sudo apt install -y ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
        Types: deb
        URIs: https://download.docker.com/linux/ubuntu
        Suites: $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$VERSION_CODENAME}")
        Components: stable
        Architectures: $(dpkg --print-architecture)
        Signed-By: /etc/apt/keyrings/docker.asc
        EOF

        sudo apt update
        sudo apt install  -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        REGION=${var.region}
        DB_ADDRESS=$(aws ssm get-parameter --name "${aws_ssm_parameter.db_address.name}" --region $REGION --query Parameter.Value --output text --with-decryption)
        DB_USERNAME=$(aws ssm get-parameter --name "${aws_ssm_parameter.db_username.name}" --region $REGION --query Parameter.Value --output text --with-decryption)
        DB_PASSWORD=$(aws ssm get-parameter --name "${aws_ssm_parameter.db_password.name}" --region $REGION --query Parameter.Value --output text --with-decryption)
        REDIS_ADDRESS=$(aws ssm get-parameter --name "${aws_ssm_parameter.redis_address.name}" --region $REGION --query Parameter.Value --output text --with-decryption)
        DB_NAME=$(aws ssm get-parameter --name "${aws_ssm_parameter.db_name.name}" --region $REGION --query Parameter.Value --output text --with-decryption)

        sudo docker run -d -p 8080:8080 --restart always \
        -e SPRING_DATASOURCE_URL=jdbc:postgresql://$DB_ADDRESS:${aws_db_instance.main.port}/$DB_NAME \
        -e SPRING_DATASOURCE_USERNAME=$DB_USERNAME \
        -e SPRING_DATASOURCE_PASSWORD=$DB_PASSWORD \
        -e SPRING_DATA_REDIS_HOST=$REDIS_ADDRESS \
        -e SPRING_DATA_REDIS_PORT=${aws_elasticache_cluster.redis.port} \
        fitcubes/backend:latest
    EOD
  )
}