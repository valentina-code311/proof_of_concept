# AWS Provider Variables
variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

# Network Variables
variable "vpc_id" {
  description = "The VPC ID where the ECS instances will be deployed"
  type        = string
}

# General Variables
variable "base_name" {
  description = "The base name of the project"
  type        = string
}
