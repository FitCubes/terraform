resource "aws_launch_template" "backend" {
  name = "${var.vpc_name}-launch-template"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  image_id = var.ami

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = var.instance_type

  monitoring {
    enabled = true
  }

  update_default_version = true

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.backend.id]
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.vpc_name}-template"
    }
  }

  user_data = base64encode(<<-EOD
        #!/bin/bash
        sudo apt update
        sudo apt install -y unzip curl
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf awscliv2.zip aws

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
        JWT_SECRET=$(aws ssm get-parameter --name "${aws_ssm_parameter.jwt_secret.name}" --region $REGION --query Parameter.Value --output text --with-decryption)

        sudo wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
        sudo apt install ./amazon-cloudwatch-agent.deb -y
        rm amazon-cloudwatch-agent.deb

        cat <<-'CFG' | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/config.json
        {
          "agent": {
            "metrics_collection_interval": 60,
            "run_as_user": "root"
          },
          "metrics": {
            "namespace": "${var.metrics_namespace}",
            "append_dimensions": {
              "InstanceId": "$${aws:InstanceId}",
              "InstanceType": "$${aws:InstanceType}",
              "AutoScalingGroupName": "$${aws:AutoScalingGroupName}"
            },
            "metrics_collected": {
              "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
                "totalcpu": true
              },
              "mem": { "measurement": ["mem_used_percent"] },
              "disk": {
                "measurement": ["used_percent"],
                "resources": ["/"]
              },
              "diskio": { "measurement": ["io_time"], "resources": ["*"] },
              "swap": { "measurement": ["swap_used_percent"] },
              "netstat": { "measurement": ["tcp_established", "tcp_time_wait"] }
            }
          },
          "logs": {
            "logs_collected": {
              "files": {
                "collect_list": [
                  {
                    "file_path": "/var/lib/docker/containers/*/*-json.log",
                    "log_group_name": "${var.log_group_name}",
                    "log_stream_name": "{instance_id}",
                    "timezone": "UTC"
                  }
                ]
              }
            }
          }
        }
        CFG
        sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
          -a fetch-config -m ec2 \
          -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json -s


        sudo docker run -d --name backend-java -p 8080:8080 --restart always \
          -e SPRING_DATASOURCE_URL=jdbc:postgresql://$DB_ADDRESS:${aws_db_instance.main.port}/$DB_NAME \
          -e SPRING_DATASOURCE_USERNAME=$DB_USERNAME \
          -e SPRING_DATASOURCE_PASSWORD=$DB_PASSWORD \
          -e SPRING_DATA_REDIS_HOST=$REDIS_ADDRESS \
          -e SPRING_DATA_REDIS_PORT=${aws_elasticache_cluster.redis.port} \
          -e JWT_SECRET=$JWT_SECRET \
          fitcubes/backend:latest
    EOD
  )
}

resource "aws_autoscaling_group" "ec2_asg" {
  name = "${var.vpc_name}-asg"

  desired_capacity = 1
  max_size         = 2
  min_size         = 1

  vpc_zone_identifier = [for subnet in aws_subnet.public : subnet.id]

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.backend.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  enabled_metrics = ["GroupInServiceInstances"]
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 100
      max_healthy_percentage = 200
      auto_rollback          = true
    }
  }
}
