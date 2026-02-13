# =============================================================================
# AWS Secrets Manager - Secure Storage for API Keys
# =============================================================================
#
# WHAT IS SECRETS MANAGER?
# Secrets Manager stores sensitive data (API keys, passwords) securely.
# Your app retrieves secrets at runtime instead of hardcoding them.
#
# WHY USE IT?
#   - Secrets are encrypted at rest
#   - Audit trail of who accessed what
#   - Can rotate secrets automatically
#   - Better than environment variables in App Runner (more secure)
#
# COST: $0.40/secret/month + $0.05 per 10,000 API calls
# =============================================================================

resource "aws_secretsmanager_secret" "api_keys" {
  name        = "${var.project_name}/api-keys"
  description = "API keys for the ${var.project_name} application"
  
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# LEARNING: The "secret version" holds the actual secret values
# You'll need to set these values after terraform apply
# Either via AWS Console or: aws secretsmanager put-secret-value
resource "aws_secretsmanager_secret_version" "api_keys" {
  secret_id = aws_secretsmanager_secret.api_keys.id
  
  # LEARNING: These are placeholder values - you'll update them after creation
  # In production, you'd use terraform.tfvars or environment variables
  secret_string = jsonencode({
    GROK_API_KEY  = "placeholder-update-after-creation"
    GROK_BASE_URL = "https://api.x.ai/v1"
  })
  
  # LEARNING: lifecycle ignore_changes prevents Terraform from overwriting
  # the secret after you've manually updated it
  lifecycle {
    ignore_changes = [secret_string]
  }
}

# -----------------------------------------------------------------------------
# IAM Policy for App Runner to read secrets
# LEARNING: This policy allows App Runner to access the secrets
# -----------------------------------------------------------------------------
resource "aws_iam_role" "apprunner_instance" {
  name = "${var.project_name}-apprunner-instance-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "tasks.apprunner.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "apprunner_secrets" {
  name = "${var.project_name}-secrets-access"
  role = aws_iam_role.apprunner_instance.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.api_keys.arn
      }
    ]
  })
}
