# Create a Security Group for the ECS execution
resource "aws_security_group" "sg" {
  name        = "${var.base_name}_sg"
  description = "Security group for ECS service execution"
  vpc_id      = var.vpc_id

  # Allow inbound traffic to ECS
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Adjust as necessary for security
  }

  # Allow outbound traffic to ECR
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Adjust as necessary for security
  }
}

# Create a Security Group for the LB
resource "aws_security_group" "lb_sg" {
  name        = "${var.base_name}_lb_sg"
  description = "Security group for the Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Adjust as necessary for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Adjust as necessary for security
  }
}
