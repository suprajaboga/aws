locals {
  bucket_policy = (var.policy_statements != null ?
    data.aws_iam_policy_document.combined.json :
    data.aws_iam_policy_document.baseline.json
  )
  log_bucket = (data.aws_region.current.name == "us-east-2" ?
    "${data.aws_iam_account_alias.current.account_alias}-s3-logging-use2" :
    "${data.aws_iam_account_alias.current.account_alias}-s3-logging-use1"
  )
  account_alias = data.aws_iam_account_alias.current.account_alias
}

resource "aws_s3_bucket" "main" {
  count         = var.enable_bucket_creation == true ? 1 : 0
  bucket        = "${local.account_alias}-${var.s3_bucket_name}"
  force_destroy = var.force_destroy

  tags = merge(
    var.tags,
    tomap({ Name = "${local.account_alias}-${var.s3_bucket_name}" })
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count  = var.enable_bucket_creation == true ? 1 : 0
  bucket = aws_s3_bucket.main[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  count  = var.enable_bucket_creation == true ? 1 : 0
  bucket = aws_s3_bucket.main[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "main" {
  count = var.enable_bucket_creation == true ? 1 : 0

  bucket = aws_s3_bucket.main[0].id
  policy = local.bucket_policy
}

resource "aws_s3_bucket_logging" "main" {
  count         = var.enable_bucket_creation == true ? 1 : 0
  bucket        = aws_s3_bucket.main[0].id
  target_bucket = local.log_bucket
  target_prefix = "access-logs/${local.account_alias}/${var.s3_bucket_name}-logs/"
}

resource "aws_s3_bucket_versioning" "main" {
  count  = var.enable_bucket_creation == true && var.enable_versioning == true ? 1 : 0
  bucket = aws_s3_bucket.main[0].id
  versioning_configuration {
    status = "Enabled"
  }
}
