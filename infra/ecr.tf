# =============================================================================
# ECR (Elastic Container Registry) - Where Docker images are stored
# =============================================================================
# 
# WHAT IS ECR?
# ECR is like Docker Hub, but private and integrated with AWS.
# When GitHub Actions builds your Docker image, it pushes it here.
# App Runner then pulls from here to run your container.
#
# FLOW: GitHub Actions → Build Image → Push to ECR → App Runner pulls from ECR
# =============================================================================

resource "aws_ecr_repository" "api" {
  name = "${var.project_name}-api"
  
  # LEARNING: image_tag_mutability controls whether you can overwrite tags
  # MUTABLE = can push same tag (e.g., "latest") multiple times
  # IMMUTABLE = each tag is permanent (better for production traceability)
  image_tag_mutability = "MUTABLE"
  
  # LEARNING: This enables scanning images for security vulnerabilities
  image_scanning_configuration {
    scan_on_push = true
  }
  
  # LEARNING: Tags help you organize and find resources in AWS Console
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# LEARNING: Lifecycle policy automatically deletes old images to save storage costs
# Without this, you'd accumulate hundreds of unused images over time
resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name
  
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
