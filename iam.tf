resource "random_id" "external_id" {
  keepers = {
    # Generate a new id each time we switch to a new AMI id
    coiled_account_id = var.coiled_account_id
  }
  byte_length = 8
}

data "aws_iam_policy_document" "cloudwatch_agent_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect = "Allow"
    resources = [
      "${aws_cloudwatch_log_group.cluster_log_group.arn}:log-stream:*",
    ]
  }
}

resource "aws_iam_policy" "cloudwatch_agent" {
  name        = "CoiledInstancePolicy"
  description = "Permissions required for the CloudWatch agent to write to your cluster log group"
  policy      = data.aws_iam_policy_document.cloudwatch_agent_policy.json
}

data "aws_iam_policy_document" "cluster_trust_document" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "coiled_cluster_role" {
  name               = "coiled-${var.coiled_workspace_name}"
  assume_role_policy = data.aws_iam_policy_document.cluster_trust_document.json
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.coiled_cluster_role.name
  policy_arn = aws_iam_policy.cloudwatch_agent.arn
}

resource "aws_iam_instance_profile" "coiled_cluster_instance_profile" {
  name = "coiled-${var.coiled_workspace_name}"
  role = aws_iam_role.coiled_cluster_role.name
}

data "aws_iam_policy_document" "control_plane_trust_document" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.coiled_account_id}:root"]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [random_id.external_id.hex]
    }
  }
}


data "aws_iam_policy_document" "ongoing_permissions" {
  statement {
    sid = "Network"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs"
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:Vpc"
      values   = ["arn:aws:${data.aws_region.current.name}:${local.current_account_id}:vpc/${aws_vpc.main.id}"]
    }
  }
  statement {
    sid = "Fleet"
    actions = [
      "ec2:CreateFleet",
    ]
    resources = ["*"]
    effect    = "Allow"
  }
  statement {
    sid = "RunInstancesInVpc"
    actions = [
      "ec2:RunInstances",
    ]
    effect    = "Allow"
    resources = ["arn:aws:ec2:${local.current_region}:${local.current_account_id}:subnet/*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:Vpc"
      values   = ["arn:aws:ec2:${local.current_region}:${local.current_account_id}:vpc/${aws_vpc.main.id}"]
    }
  }
  statement {
    sid = "RunInstancesImage"
    actions = [
      "ec2:RunInstances",
    ]
    effect    = "Allow"
    resources = ["arn:aws:ec2:${local.current_region}::image/*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:Owner"
      values   = [var.coiled_account_id]
    }
  }
  statement {
    sid = "RemainingRunInstancePermissions"
    actions = [
      "ec2:RunInstances",
    ]
    effect = "Allow"
    resources = [
      "arn:aws:ec2:${local.current_region}:${local.current_account_id}:instance/*",
      "arn:aws:ec2:${local.current_region}:${local.current_account_id}:volume/*",
      "arn:aws:ec2:us-east-1::snapshot/*",
      "arn:aws:ec2:${local.current_region}:${local.current_account_id}:network-interface/*",
      "arn:aws:ec2:${local.current_region}:${local.current_account_id}:key-pair/*",
      "arn:aws:ec2:${local.current_region}:${local.current_account_id}:security-group/*",
      "arn:aws:ec2:${local.current_region}:${local.current_account_id}:launch-template/*"
    ]
  }
  statement {
    sid = "TerminateInstances"
    actions = [
      "ec2:TerminateInstances",
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/owner"
      values   = ["coiled"]
    }
  }
  statement {
    sid = "Passrole"
    actions = [
      "iam:Passrole",
    ]
    effect    = "Allow"
    resources = [aws_iam_role.coiled_cluster_role.arn]
  }
  statement {
    sid = "LoggingDescribe"
    actions = [
      "logs:DescribeLogGroups",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = "LoggingRead"
    actions = [
      "logs:DescribeLogStreams",
      "logs:FilterLogEvents",
      "logs:GetLogEvents",
    ]
    resources = [aws_cloudwatch_log_group.cluster_log_group.arn]
  }
  statement {
    sid = "ECRAccess"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = ["arn:aws:ecr:${local.current_region}:${local.current_account_id}:repository/*"]
  }
  statement {
    sid       = "ECRToken"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    sid    = "LaunchTemplateManagement"
    effect = "Allow"
    actions = [
      "ec2:CreateLaunchTemplate",
      "ec2:CreateLaunchTemplateVersion",
      "ec2:DeleteLaunchTemplate",
      "ec2:DescribeLaunchTemplates",
      "ec2:DeleteLaunchTemplateVersions",
    ]
    resources = ["arn:aws:ec2:${local.current_region}:${local.current_account_id}:launch-template/*"]
  }
  statement {
    sid    = "EverythingElse"
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeRegions",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "iam:GetInstanceProfile",
      "sts:GetCallerIdentity"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "setup_permissions" {
  statement {
    sid       = "setup"
    effect    = "Allow"
    resources = [aws_iam_role.coiled_cluster_role.arn]
    actions   = ["iam:GetRole"]
  }
  statement {
    sid       = "policy"
    effect    = "Allow"
    actions   = ["iam:GetPolicy"]
    resources = [aws_iam_policy.cloudwatch_agent.arn]
  }
  statement {
    sid       = "instanceprofile"
    effect    = "Allow"
    actions   = ["iam:GetInstanceProfile"]
    resources = [aws_iam_instance_profile.coiled_cluster_instance_profile.arn]
  }
  statement {
    sid       = "listrolepolicies"
    effect    = "Allow"
    actions   = ["iam:ListAttachedRolePolicies"]
    resources = [aws_iam_role.coiled_cluster_role.arn]
  }
}

resource "aws_iam_policy" "ongoing" {
  name        = "coiled-ongoing-policy"
  description = "Permissions required for Coiled to operate in your AWS account"
  policy      = data.aws_iam_policy_document.ongoing_permissions.json
}
resource "aws_iam_policy" "setup" {
  name        = "coiled-setup-policy"
  description = "Permissions required for Coiled to operate in your AWS account"
  policy      = data.aws_iam_policy_document.setup_permissions.json
}


resource "aws_iam_role" "coiled_control_plane_role" {
  name               = "coiled-control-plane-role"
  assume_role_policy = data.aws_iam_policy_document.control_plane_trust_document.json
}

resource "aws_iam_role_policy_attachment" "ongoing" {
  role       = aws_iam_role.coiled_control_plane_role.name
  policy_arn = aws_iam_policy.ongoing.arn
}

resource "aws_iam_role_policy_attachment" "setup" {
  role       = aws_iam_role.coiled_control_plane_role.name
  policy_arn = aws_iam_policy.setup.arn
}
