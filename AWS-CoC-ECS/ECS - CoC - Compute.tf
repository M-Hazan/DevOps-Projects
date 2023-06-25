

resource "aws_ecs_cluster" "CoC-Fargate-Cluster" {
    name = "CoC-Fargate-Cluster"
}

resource "aws_ecs_cluster" "CoC-ECS-Task-Definition" {
    family = "service"
    requires_compatibilities = ["FARGATE"]
    network_mode = "awsvpc"
    cpu = "256"
    memory = "512"

    container_definitions = <<DEFINITION
    [
        {
      "name": "your_container_name",
      "image": "your_docker_image_on_dockerhub",
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