data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "wg_instance_profile_doc" {
  statement {
    sid = "SSMAccess"

    effect = "Allow"

    actions = ["ssm:GetParameters"]

    resources = [data.aws_ssm_parameter.wg_server_private_key.arn]
  }

  statement {
    sid = "KMSAccess"

    effect = "Allow"

    actions = ["kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]

    resources = ["arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/*"]
  }
}

data "aws_iam_policy_document" "wg_instance_profile_assume_role_doc" {
  statement {

    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "wg_instance_policy" {
  name        = "wg_instance_policy"
  description = "Allow Wireguard Instance access to AWS resources via IAM"

  policy = data.aws_iam_policy_document.wg_instance_profile_doc.json
}

resource "aws_iam_role" "wg_instance_role" {
  name               = "wg-instance-role"
  assume_role_policy = data.aws_iam_policy_document.wg_instance_profile_assume_role_doc.json
}

resource "aws_iam_role_policy_attachment" "wg_instance_role_policy_attachment" {
  role       = aws_iam_role.wg_instance_role.name
  policy_arn = aws_iam_policy.wg_instance_policy.arn
}

resource "aws_iam_instance_profile" "wg_instance_profile" {
  name = "wg-instance-profile"
  role = aws_iam_role.wg_instance_role.name
}
