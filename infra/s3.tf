# =============================================================================
# S3 Bucket - Static File Storage for Frontend
# =============================================================================
#
# WHAT IS S3?
# S3 (Simple Storage Service) stores files in the cloud.
# For web hosting, we use it to serve static files (HTML, CSS, JS).
#
# WHY S3 + CLOUDFRONT?
#   S3 alone: Works, but slow for users far from the AWS region
#   S3 + CloudFront: Files cached at 400+ edge locations worldwide = FAST
#
# FLOW: User → CloudFront (cached) → S3 (origin)
# =============================================================================

resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${random_id.bucket_suffix.hex}"
  
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# LEARNING: S3 bucket names must be globally unique across ALL AWS accounts
# random_id generates a random suffix to avoid name conflicts
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# -----------------------------------------------------------------------------
# Block Public Access
# LEARNING: We DON'T want the S3 bucket directly accessible to the public
# Instead, only CloudFront can access it (more secure, faster, cheaper)
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# Origin Access Control (OAC)
# LEARNING: This creates a special identity for CloudFront
# S3 only allows requests from this identity (not direct public access)
# -----------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${var.project_name}-frontend-oac"
  description                       = "OAC for frontend S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# -----------------------------------------------------------------------------
# S3 Bucket Policy
# LEARNING: This policy says "only CloudFront can read from this bucket"
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
          }
        }
      }
    ]
  })
}
