data "aws_caller_identity" "current" {}
data "aws_iam_policy_document" "iam-role-policy" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.backend.id}"]
  }

  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.backend.id}/*"]
  }

  statement {
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = ["arn:aws:dynamodb:*:*:table/terraform-lock"]
  }
}

data "aws_iam_policy_document" "backend-assume-role-all" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = split(",", lookup(var.assume_policy, "all", data.aws_caller_identity.current.account_id))
    }
  }
}

resource "aws_iam_role" "backend-all" {
  name               = "terraform-backend"
  description        = "Allows access to all Terraform workspaces"
  assume_role_policy = data.aws_iam_policy_document.backend-assume-role-all.json
}

resource "aws_iam_role_policy" "backend-all" {
  name   = "terraform-backend"
  policy = data.aws_iam_policy_document.iam-role-policy.json
  role   = "terraform-backend"

  depends_on = [aws_iam_role.backend-all]
}
