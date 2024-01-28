
#1 #Create S3 Bucket 
resource "aws_s3_bucket" "bucket" {
  bucket = "cloudy-day-for-a-ninja-1"
}
#bucket objects
resource "aws_s3_object" "ninjafile" {
  for_each     = var.objects
  bucket       = aws_s3_bucket.bucket.id
  key          = each.key
  source       = "./Content/${each.key}"
  content_type = each.value
  #etag         = filemd5(each.value)
  acl = "public-read"
}
# Bucket Versioning is disabled
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_website_configuration" "hosting" {
  bucket = aws_s3_bucket.bucket.id

  index_document {
    suffix = "index.html"
  }
  depends_on = [aws_s3_bucket_acl.s3acl]
}
## 2 Configure Bucket Ownership to "BucketOwnerPreferred"
resource "aws_s3_bucket_ownership_controls" "s3controls" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
# Set Public access controls
resource "aws_s3_bucket_public_access_block" "PABs" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls   = false
  block_public_policy = false
  #ignore_public_acls      = false
  #restrict_public_buckets = false
}
# ACL for bucket
resource "aws_s3_bucket_acl" "s3acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.s3controls,
    aws_s3_bucket_public_access_block.PABs,
  ]

  bucket = aws_s3_bucket.bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "PublicReadGetObject",
          "Effect" : "Allow",
          "Principal" : "*",
          "Action" : "s3:GetObject",
          "Resource" : "arn:aws:s3:::${aws_s3_bucket.bucket.id}/*"

        }
      ]
    }
  )
}