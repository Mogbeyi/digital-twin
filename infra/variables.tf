# Variables for the infrastructure

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "digital-twin"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "groq_api_key" {
  description = "Groq API key for the LLM"
  type        = string
  sensitive   = true
}

variable "groq_base_url" {
  description = "Groq API base URL"
  type        = string
  default     = "https://api.x.ai/v1"
}

variable "alert_email" {
  description = "Email address for CloudWatch alerts (optional)"
  type        = string
  default     = ""
}

