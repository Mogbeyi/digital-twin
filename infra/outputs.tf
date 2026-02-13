# =============================================================================
# Terraform Outputs - Important values you'll need
# =============================================================================
#
# WHAT ARE OUTPUTS?
# Outputs display important information after terraform apply.
# They're like return values from your infrastructure.
#
# Usage: terraform output <output_name>
# Example: terraform output cloudfront_url
# =============================================================================

# -----------------------------------------------------------------------------
# ECR Outputs
# -----------------------------------------------------------------------------
output "ecr_repository_url" {
  description = "URL to push Docker images to"
  value       = aws_ecr_repository.api.repository_url
}

output "ecr_registry_id" {
  description = "ECR registry ID (your AWS account ID)"
  value       = aws_ecr_repository.api.registry_id
}

# -----------------------------------------------------------------------------
# App Runner Outputs
# -----------------------------------------------------------------------------
output "api_url" {
  description = "Public URL of your API (App Runner)"
  value       = aws_apprunner_service.api.service_url
}

# -----------------------------------------------------------------------------
# Frontend Outputs
# -----------------------------------------------------------------------------
output "cloudfront_url" {
  description = "Public URL of your frontend (CloudFront)"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (needed to invalidate cache)"
  value       = aws_cloudfront_distribution.frontend.id
}

output "s3_bucket_name" {
  description = "S3 bucket name for frontend files"
  value       = aws_s3_bucket.frontend.id
}

# -----------------------------------------------------------------------------
# Secrets Manager Outputs
# -----------------------------------------------------------------------------
output "secrets_arn" {
  description = "ARN of the secrets (use in App Runner config)"
  value       = aws_secretsmanager_secret.api_keys.arn
}

# -----------------------------------------------------------------------------
# Helper Commands
# -----------------------------------------------------------------------------
output "next_steps" {
  description = "Commands to run after terraform apply"
  value       = <<-EOT
    
    ✅ Infrastructure created! Next steps:
    
    1. Push Docker image to ECR:
       aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.api.repository_url}
       docker build -t ${aws_ecr_repository.api.repository_url}:latest -f Dockerfile.api .
       docker push ${aws_ecr_repository.api.repository_url}:latest
    
    2. Update secrets in AWS Console:
       Go to: https://console.aws.amazon.com/secretsmanager/
       Find: ${var.project_name}/api-keys
       Update with your real GROK_API_KEY
    
    3. Deploy frontend:
       cd frontend && npm run build
       aws s3 sync out/ s3://${aws_s3_bucket.frontend.id}/ --delete
       aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.frontend.id} --paths "/*"
    
    4. Your URLs:
       API:      https://${aws_apprunner_service.api.service_url}
       Frontend: https://${aws_cloudfront_distribution.frontend.domain_name}
    
  EOT
}
