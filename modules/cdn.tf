resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = ""  # not serving a website root, so keep blank

  origin {
    domain_name = aws_s3_bucket.files.bucket_regional_domain_name
    origin_id   = "S3-origin"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.files_oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id       = "S3-origin"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    # Cache policy: use default (caches by URL path)
      forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    # We can customize cache settings if needed
  }

  price_class = "PriceClass_100"  # use a subset of edge locations (change to _All or _200 as needed)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
    # In production, you might use a custom domain and ACM certificate
  }
}
