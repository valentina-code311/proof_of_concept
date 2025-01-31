# Create the ECR repositories
resource "aws_ecr_repository" "repo" {
  name         = "${var.base_name}_repo"
  force_delete = true
}

# Create the ECS cluster
resource "aws_ecs_cluster" "cluster" {
  name  = "${var.base_name}_cluster"
}

# Create the Task definitions
resource "aws_ecs_task_definition" "task" {
  family                   = "${var.base_name}_task"
  network_mode             = "awsvpc"
  task_role_arn            = aws_iam_role.roles["ecsServiceExecution"].arn
  execution_role_arn       = aws_iam_role.roles["ecsServiceExecution"].arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  container_definitions    = templatefile("../tasks/app.json", {
    account_id   = local.account_id
    region       = var.region
    service_name = var.base_name
  })
}

resource "aws_ecs_service" "service" {
  depends_on = [aws_lb_listener.listener]

  name            = "${var.base_name}_service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 0
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "${var.base_name}_app"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}
