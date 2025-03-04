data "aws_iam_account_alias" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_policy_document" "baseline" {
  statement {
    sid    = "EnforceOnTransitEncryption"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:*"
    ]

    resources = [
      try(aws_s3_bucket.main[0].arn,""),
      "${try(aws_s3_bucket.main[0].arn,"")}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "custom" {
  dynamic "statement" {
    for_each = var.policy_statements

    content {
      sid       = try(statement.value.sid, null)
      actions   = try(statement.value.actions, null)
      effect    = try(statement.value.effect, null)
      resources = try(statement.value.resources, null)

      dynamic "principals" {
        for_each = try(statement.value.principals, [])

        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = try(statement.value.conditions, [])

        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }
}

data "aws_iam_policy_document" "combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.baseline.json,
    data.aws_iam_policy_document.custom.json
  ]
}
