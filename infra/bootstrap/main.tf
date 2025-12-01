locals {
  # Example: jasoncorrea56-cs-fundamentals-tfstate-prod-us-west-2
  bucket_name = "${var.org}-${var.project}-tfstate-${var.env}-${var.region}"
}

resource "aws_kms_key" "tf_state" {
  description             = "KMS key for Terraform state and lock table"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Project = var.project
    Env     = var.env
    Owner   = var.owner
    Purpose = "terraform-state-kms"
  }
}

##########################
# State Bucket Resources #
##########################

resource "aws_s3_bucket" "tfstate" {
  bucket        = local.bucket_name
  force_destroy = true

  tags = {
    Project = var.project
    Env     = var.env
    Owner   = var.owner
    Purpose = "terraform-state"
  }
}

# Keep every revision of state (for roll backs)
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption (KMS)
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.tf_state.arn
    }
  }
}

# Block public access (all four)
resource "aws_s3_bucket_public_access_block" "pab" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Basic bucket policy: deny unencrypted transport
data "aws_iam_policy_document" "deny_insecure" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    resources = [
      aws_s3_bucket.tfstate.arn,
      "${aws_s3_bucket.tfstate.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.tfstate.id
  policy = data.aws_iam_policy_document.deny_insecure.json
}

# DynamoDB table for state locks
resource "aws_dynamodb_table" "tf_locks" {
  name         = "${var.org}-${var.project}-tf-locks-${var.env}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # Encryption at rest using customer-managed KMS key
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.tf_state.arn
  }

  # Point-in-time recovery for accidental/malicious changes
  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Project = var.project
    Env     = var.env
    Owner   = var.owner
    Purpose = "terraform-state-locks"
  }
}

##############################
# State Log Bucket Resources #
##############################

resource "aws_s3_bucket" "tfstate_logs" {
  bucket        = "${local.bucket_name}-logs"
  force_destroy = true

  tags = {
    Project = var.project
    Env     = var.env
    Owner   = var.owner
    Purpose = "terraform-state-access-logs"
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate_logs" {
  bucket                  = aws_s3_bucket.tfstate_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Ship state bucket access logs to the logging bucket
resource "aws_s3_bucket_logging" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  target_bucket = aws_s3_bucket.tfstate_logs.id
  target_prefix = "s3-access-logs/"
}

resource "aws_s3_bucket_lifecycle_configuration" "tfstate_logs" {
  bucket = aws_s3_bucket.tfstate_logs.id

  rule {
    id     = "expire-access-logs"
    status = "Enabled"

    filter {
      prefix = "" # Apply to all objects
    }

    expiration {
      days = 90
    }
  }
}
