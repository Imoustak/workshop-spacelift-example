module "networking" {
  source = "github.com/spacelift-solutions/terraform-spacelift-stack?ref=v3.2.1"

  name        = "networking"
  description = "AWS networking (VPC, subnets, routing) for the workshop"

  space_id          = spacelift_space.workshop.id
  repository_name   = var.repository_name
  repository_branch = var.repository_branch
  project_root      = "aws/networking"
  vcs               = var.vcs

  workflow_tool = "OPEN_TOFU"
  tf_version    = var.tf_version

  aws_integration = {
    enabled = true
    id      = var.aws_integration_id
  }

  labels = ["aws", "networking", "opentofu"]
}

module "kubernetes" {
  source = "github.com/spacelift-solutions/terraform-spacelift-stack?ref=v3.2.1"

  name        = "kubernetes"
  description = "AWS EKS cluster for the workshop"

  space_id          = spacelift_space.workshop.id
  repository_name   = var.repository_name
  repository_branch = var.repository_branch
  project_root      = "aws/eks"
  vcs               = var.vcs

  workflow_tool = "OPEN_TOFU"
  tf_version    = var.tf_version

  aws_integration = {
    enabled = true
    id      = var.aws_integration_id
  }

  labels = ["aws", "eks", "kubernetes", "opentofu"]
}
