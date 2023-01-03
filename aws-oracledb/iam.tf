resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.resource_name_prefix}-oracledb-instance-profile"
  role = var.user_supplied_iam_role_name != null ? var.user_supplied_iam_role_name : aws_iam_role.instance_role[0].name
}

resource "aws_iam_role" "instance_role" {
  count                = var.user_supplied_iam_role_name != null ? 0 : 1
  name                 = "${var.resource_name_prefix}-oracledb-instance-role"
  permissions_boundary = var.permissions_boundary
  assume_role_policy   = data.aws_iam_policy_document.instance_role.json
}

data "aws_iam_policy_document" "instance_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "session_manager" {
  count  = var.user_supplied_iam_role_name != null ? 0 : 1
  name   = "${var.resource_name_prefix}-oracledb-ssm"
  role   = aws_iam_role.instance_role[0].id
  policy = data.aws_iam_policy_document.session_manager.json
}

data "aws_iam_policy_document" "session_manager" {
  statement {
    sid    = "AllowSSM"
    effect = "Allow"
    actions = [
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "secrets_manager" {
  count  = var.user_supplied_iam_role_name != null || length(var.sm_secrets_arns) == 0 ? 0 : 1
  name   = "${var.resource_name_prefix}-oracledb-secrets-manager"
  role   = aws_iam_role.instance_role[0].id
  policy = data.aws_iam_policy_document.secrets_manager.json
}

data "aws_iam_policy_document" "secrets_manager" {
  statement {
    sid    = "AllowAccessToSecretsManagerSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = var.sm_secrets_arns
  }
}

resource "aws_iam_role_policy" "cloudwatch" {
  count  = var.user_supplied_iam_role_name != null ? 0 : 1
  name   = "${var.resource_name_prefix}-oracledb-cloudwatch"
  role   = aws_iam_role.instance_role[0].id
  policy = data.aws_iam_policy_document.cloudwatch.json
}

data "aws_iam_policy_document" "cloudwatch" {
  statement {
    sid    = "AllowCloudwatchLogging"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:CreateLogGroup"
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "ec2" {
  count  = var.user_supplied_iam_role_name != null ? 0 : 1
  name   = "${var.resource_name_prefix}-oracledb-ec2"
  role   = aws_iam_role.instance_role[0].id
  policy = data.aws_iam_policy_document.ec2.json
}

data "aws_iam_policy_document" "ec2" {
  statement {
    sid    = "AllowDescribeVolumeOnInstance"
    effect = "Allow"
    actions = [
      "ec2:DescribeVolumes",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "s3_buckets" {
  count  = var.user_supplied_iam_role_name != null ? 0 : 1
  name   = "${var.resource_name_prefix}-oracledb-s3-buckets"
  role   = aws_iam_role.instance_role[0].id
  policy = data.aws_iam_policy_document.s3_buckets.json
}

data "aws_iam_policy_document" "s3_buckets" {
  statement {
    sid    = "AllowReadWriteAccessToS3BucketsListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = formatlist("arn:aws:s3:::%s", var.buckets_access)
  }
  statement {
    sid    = "AllowReadWriteAccessToS3BucketsCrud"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = formatlist("arn:aws:s3:::%s/*", var.buckets_access)
  }
}