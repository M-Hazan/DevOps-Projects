

resource "aws_ecs_cluster" "CoC-Fargate-Cluster" {
  name = "CoC-Fargate-Cluster"
}

resource "aws_ecs_task_definition" "CoC-ECS-Task-Definition" {
  family                   = "service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  container_definitions = <<DEFINITION
    [
        {
        "name": "spud-CoC",
        "image": "docker.io/acantril/containerofcats",
        "essential": true,
        "portMappings": [
            {
            "containerPort": 80,
            "hostPort": 80
            }
        ]
        }
    ]
    DEFINITION
}

resource "aws_ecs_service" "CoC-Service" {
  name            = "CoC-Service"
  cluster         = aws_ecs_cluster.CoC-Fargate-Cluster.id
  task_definition = aws_ecs_task_definition.CoC-ECS-Task-Definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.Spudinaws-Public-Subnet_us-east-1a.id, aws_subnet.Spudinaws-Public-Subnet_us-east-1b.id]
    security_groups  = [aws_security_group.Terraform_CoC-SG.id]
    assign_public_ip = true
  }
}