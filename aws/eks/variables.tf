variable "region" {
  type        = string
  description = "AWS region the EKS cluster is created in."
  default     = "eu-west-1"
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster. Must match the cluster_name used by the networking stack so the subnet discovery tags line up."
  default     = "workshop"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes <major>.<minor> version of the control plane. 1.36 is the newest version available on Amazon EKS."
  default     = "1.36"
}

variable "node_pools" {
  type        = list(string)
  description = "EKS Auto Mode built-in node pools to enable. 'system' hosts critical add-ons, 'general-purpose' hosts workloads."
  default     = ["system", "general-purpose"]
}

variable "endpoint_public_access" {
  type        = bool
  description = "Expose the Kubernetes API server endpoint publicly. Needed to reach the cluster from outside the VPC."
  default     = true
}

variable "cluster_admin_principal_arns" {
  type        = list(string)
  description = "IAM principal ARNs granted cluster-wide admin through an EKS access entry. The stack is applied by the Spacelift AWS integration role, so enable_cluster_creator_admin_permissions only covers that role — human users need to be listed here to reach the cluster with kubectl."
  default     = ["arn:aws:iam::247747705325:user/emin"]
}

################################################################################
# Networking references
#
# Populated from the outputs of the networking stack. Left empty on purpose so
# they can be injected as environment variables (TF_VAR_<name>) — either via a
# Spacelift context shared with the networking stack, or via stack outputs.
################################################################################

variable "vpc_id" {
  type        = string
  description = "ID of the VPC the cluster is deployed into. Set via TF_VAR_vpc_id."
  default     = ""
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "IDs of the private subnets Auto Mode places nodes in. Set via TF_VAR_private_subnet_ids, e.g. '[\"subnet-a\",\"subnet-b\"]'."
  default     = []
}

variable "control_plane_subnet_ids" {
  type        = list(string)
  description = "IDs of the subnets the control plane ENIs are placed in. Falls back to private_subnet_ids when empty. Set via TF_VAR_control_plane_subnet_ids."
  default     = []
}

################################################################################
# EKS capabilities
################################################################################

variable "ack_iam_role_policies" {
  type        = map(string)
  description = "IAM policies attached to the ACK capability role, in {name = policy_arn} format. AdministratorAccess is what the upstream example uses and is fine for a workshop — scope it down to the AWS services ACK actually manages for anything real."
  default = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }
}

variable "argocd_namespace" {
  type        = string
  description = "Namespace the managed Argo CD capability is installed into."
  default     = "argocd"
}

variable "argocd_idc_instance_arn" {
  type        = string
  description = "ARN of the IAM Identity Center instance Argo CD authenticates against. Discovered from the account when empty. Set via TF_VAR_argocd_idc_instance_arn."
  default     = ""
}

variable "argocd_admin_sso_group_ids" {
  type        = list(string)
  description = "IAM Identity Center group IDs granted the Argo CD ADMIN role. No RBAC mapping is created when empty."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource."
  default = {
    Project   = "workshop"
    ManagedBy = "spacelift"
  }
}
