module "simple_bucket" {
  source = "./environments/modules/s3/"
  

  s3_bucket_name = "patch-reports-use2"
  kms_key_arn    = module.simple_key.key_arn

  # Bucket policy
  policy_statements = [
    {
      principals = [
        {
          type = "AWS"
          identifiers = ["*"]
        }
      ]
      actions = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ]
      effect = "Allow"
      resources = [
        "${module.simple_bucket.bucket_arn}/*"
      ]
      conditions = [
        {
          test     = "StringEquals"
          variable = "aws:PrincipalOrgID"
          values   = ["o-ie70f219nn", "o-ie1yc8zvv5"]
        },
        {
          test     = "ArnLike"
          variable = "aws:PrincipalArn"
          values   = ["arn:aws:iam::142174879951:role/erieins-logarchive-prd-patch-replication-role"]
        }
      ]
    }
  ]
}
