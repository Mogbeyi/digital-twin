# =============================================================================
# CloudFront - Content Delivery Network (CDN)
# =============================================================================
#
# WHAT IS CLOUDFRONT?
# CloudFront caches your content at 400+ "edge locations" worldwide.
# When a user in Tokyo requests your site, they get it from a Tokyo server,
# not from us-east-1. This makes your site FAST globally.
#
# HOW IT WORKS:
#   1. User requests yourdomain.com
#   2. CloudFront checks if it has a cached copy at the nearest edge
#   3. If yes → serves immediately (fast!)
#   4. If no → fetches from S3 (origin), caches it, serves to user
#
# COST: Very cheap for low traffic (often free tier), ~$0.085/GB after
# =============================================================================

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} frontend"
  default_root_object = "index.html"  # Serve index.html when user visits /
  
  # LEARNING: "origin" defines where CloudFront fetches content from
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.frontend.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }
  
  # LEARNING: default_cache_behavior controls how CloudFront handles requests
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend.id}"
    
    # LEARNING: forwarded_values controls what's sent to origin
    # For static sites, we don't need to forward query strings or cookies
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    # LEARNING: Forces HTTPS - users typing http:// get redirected to https://
    viewer_protocol_policy = "redirect-to-https"
    
    # LEARNING: TTL = Time To Live (how long to cache)
    min_ttl     = 0
    default_ttl = 3600   # 1 hour default cache
    max_ttl     = 86400  # 24 hours max cache
  }
  
  # LEARNING: This handles client-side routing for React/Next.js apps
  # When someone goes to /about, CloudFront returns index.html (which handles routing)
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }
  
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }
  
  # LEARNING: restrictions can limit which countries can access your site
  # "none" means no restrictions (available worldwide)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  # LEARNING: SSL/TLS certificate for HTTPS
  # "cloudfront_default_certificate" = free AWS certificate
  # For custom domain, you'd use ACM (AWS Certificate Manager)
  viewer_certificate {
    cloudfront_default_certificate = true
    # To use custom domain, uncomment below and create ACM certificate:
    # acm_certificate_arn      = aws_acm_certificate.example.arn
    # ssl_support_method       = "sni-only"
  }
  
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
