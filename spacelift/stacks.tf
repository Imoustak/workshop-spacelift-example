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
  auto_deploy   = true

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
  auto_deploy   = true

  aws_integration = {
    enabled = true
    id      = var.aws_integration_id
  }

  # The EKS cluster is built on top of the VPC, so the kubernetes stack runs
  # after networking and reads the subnet/VPC IDs straight out of its outputs.
  # control_plane_subnet_ids is left unwired on purpose — the EKS module falls
  # back to subnet_ids for the control plane ENIs when it is empty.
  dependencies = {
    networking = {
      parent_stack_id = module.networking.id

      references = {
        vpc_id = {
          input_name  = "TF_VAR_vpc_id"
          output_name = "vpc_id"
        }
        private_subnet_ids = {
          input_name  = "TF_VAR_private_subnet_ids"
          output_name = "private_subnets"
        }
      }
    }
  }

  labels = ["aws", "eks", "kubernetes", "opentofu"]
}
