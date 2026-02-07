# =============================================================================
# App Runner - Serverless Container Hosting for Your API
# =============================================================================
#
# WHAT IS APP RUNNER?
# App Runner runs your Docker container without you managing servers.
# It automatically:
#   - Pulls your image from ECR
#   - Handles HTTPS/SSL certificates
#   - Scales up/down based on traffic
#   - Provides a public URL
#
# COMPARISON:
#   EC2 = You manage everything (servers, scaling, SSL)
#   ECS = You manage cluster configuration
#   App Runner = AWS manages everything, you just provide the container
# =============================================================================

# -----------------------------------------------------------------------------
# IAM Role for App Runner
# LEARNING: App Runner needs permission to pull images from ECR
# This role says "App Runner is allowed to access my ECR repository"
# -----------------------------------------------------------------------------
resource "aws_iam_role" "apprunner_ecr_access" {
  name = "${var.project_name}-apprunner-ecr-role"
  
  # LEARNING: This "assume_role_policy" defines WHO can use this role
  # Here, we're saying only the App Runner build service can assume it
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
      }
    ]
  })
}

# LEARNING: Attach the AWS-managed policy that grants ECR read access
resource "aws_iam_role_policy_attachment" "apprunner_ecr" {
  role       = aws_iam_role.apprunner_ecr_access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# -----------------------------------------------------------------------------
# App Runner Service - The actual running API
# -----------------------------------------------------------------------------
resource "aws_apprunner_service" "api" {
  service_name = "${var.project_name}-api"
  
  # LEARNING: source_configuration tells App Runner where to get your code
  source_configuration {
    
    # We're using ECR (container image), not GitHub (source code)
    image_repository {
      image_identifier      = "${aws_ecr_repository.api.repository_url}:latest"
      image_repository_type = "ECR"
      
      # LEARNING: image_configuration sets container runtime options
      image_configuration {
        port = "8000"  # The port your FastAPI runs on
        
        # LEARNING: Environment variables for your app
        # NOTE: For production, consider using AWS Secrets Manager with
        # runtime_environment_secrets instead of plain environment variables
        runtime_environment_variables = {
          ENVIRONMENT   = var.environment
          GROQ_API_KEY  = var.groq_api_key
          GROQ_BASE_URL = var.groq_base_url
        }
      }
    }
    
    # LEARNING: auto_deployments_enabled = true means:
    # Every time you push a new image to ECR, App Runner auto-deploys it
    auto_deployments_enabled = true
    
    # The IAM role we created above
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_access.arn
    }
  }
  
  # LEARNING: instance_configuration controls the container size and scaling
  instance_configuration {
    cpu    = "256"   # 0.25 vCPU (smallest, cheapest option)
    memory = "512"   # 512 MB RAM
    
    # LEARNING: You can also set instance_role_arn here if your app
    # needs to access other AWS services (like S3, DynamoDB, etc.)
  }
  
  # Connect to our cost-optimized auto-scaling configuration
  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.cost_optimized.arn
  
  # LEARNING: health_check_configuration tells App Runner how to know if your app is healthy
  health_check_configuration {
    protocol            = "HTTP"
    path                = "/api/health"  # Your health check endpoint
    interval            = 10             # Check every 10 seconds
    timeout             = 5              # Wait up to 5 seconds for response
    healthy_threshold   = 1              # 1 success = healthy
    unhealthy_threshold = 5              # 5 failures = unhealthy, restart
  }
  
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Auto Scaling Configuration - CRITICAL FOR COST OPTIMIZATION
# LEARNING: This controls how App Runner scales your service
# -----------------------------------------------------------------------------
resource "aws_apprunner_auto_scaling_configuration_version" "cost_optimized" {
  auto_scaling_configuration_name = "${var.project_name}-scaling"
  
  # LEARNING: min_size = 1 keeps one instance always running
  # Note: AWS App Runner requires min_size >= 1
  # With 0.25 vCPU this costs ~$5/month but avoids cold starts
  min_size = 1
  
  # LEARNING: max_size limits how much you can scale up
  # This prevents surprise bills during traffic spikes
  max_size = 3
  
  # LEARNING: max_concurrency = requests per instance before scaling up
  # Lower = more responsive scaling, higher = more efficient
  # For chatbots with long requests, 50 is a good balance
  max_concurrency = 50
  
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

