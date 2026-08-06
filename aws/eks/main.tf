# The Argo CD capability authenticates users through IAM Identity Center, so it
# needs the ARN of the account's IDC instance. Discovered here unless overridden.
data "aws_ssoadmin_instances" "this" {
  count = var.argocd_idc_instance_arn == "" ? 1 : 0
}

locals {
  argocd_idc_instance_arn = var.argocd_idc_instance_arn != "" ? var.argocd_idc_instance_arn : one(data.aws_ssoadmin_instances.this[0].arns)

  # One access entry per admin principal, keyed by the last segment of the ARN
  # (e.g. "user/emin" -> "emin") so the map keys stay stable and readable.
  cluster_admin_access_entries = {
    for arn in var.cluster_admin_principal_arns : reverse(split("/", arn))[0] => {
      principal_arn = arn
      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  argocd_rbac_role_mapping = length(var.argocd_admin_sso_group_ids) > 0 ? [{
    role = "ADMIN"
    identity = [for group_id in var.argocd_admin_sso_group_ids : {
      id   = group_id
      type = "SSO_GROUP"
    }]
  }] : null
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.24"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  endpoint_public_access                   = var.endpoint_public_access
  enable_cluster_creator_admin_permissions = true

  # Auth is access-entry based (API mode); aws-auth ConfigMap is not used.
  access_entries = local.cluster_admin_access_entries

  # EKS Auto Mode. Enabling compute_config also turns on the managed block
  # storage (EBS CSI) and load balancing (ALB/NLB) capabilities of Auto Mode,
  # so no self-managed node groups or core add-ons are needed.
  compute_config = {
    enabled    = true
    node_pools = var.node_pools
  }

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids

  tags = var.tags
}

################################################################################
# EKS capabilities — AWS-managed platform components running outside the cluster
################################################################################

# AWS Controllers for Kubernetes: manage AWS resources through the Kubernetes API.
module "ack" {
  source  = "terraform-aws-modules/eks/aws//modules/capability"
  version = "~> 21.24"

  type         = "ACK"
  cluster_name = module.eks.cluster_name

  iam_role_policies = var.ack_iam_role_policies

  tags = var.tags
}

# Kube Resource Orchestrator: compose resources into higher-level custom APIs.
module "kro" {
  source  = "terraform-aws-modules/eks/aws//modules/capability"
  version = "~> 21.24"

  type         = "KRO"
  cluster_name = module.eks.cluster_name

  tags = var.tags
}

# Fully managed Argo CD for GitOps delivery into the cluster.
module "argocd" {
  source  = "terraform-aws-modules/eks/aws//modules/capability"
  version = "~> 21.24"

  type         = "ARGOCD"
  cluster_name = module.eks.cluster_name

  configuration = {
    argo_cd = {
      aws_idc = {
        idc_instance_arn = local.argocd_idc_instance_arn
        idc_region       = var.region
      }
      namespace         = var.argocd_namespace
      rbac_role_mapping = local.argocd_rbac_role_mapping
    }
  }

  # Argo CD pulls manifests and images; ECR read access covers the common case.
  iam_policy_statements = {
    ECRRead = {
      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
      ]
      resources = ["*"]
    }
  }

  tags = var.tags
}
