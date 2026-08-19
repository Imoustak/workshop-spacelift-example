variable "region" {
  type        = string
  description = "AWS region the VPC is created in."
  default     = "eu-east-1"
}

variable "name" {
  type        = string
  description = "Name prefix applied to the VPC and its child resources."
  default     = "workshop"
}

variable "cidr" {
  type        = string
  description = "IPv4 CIDR block of the VPC."
  default     = "10.0.0.0/16"
}

variable "az_count" {
  type        = number
  description = "Number of availability zones to spread the subnets across."
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "az_count must be between 2 and 4."
  }
}

variable "single_nat_gateway" {
  type        = bool
  description = "Route all private subnets through a single NAT gateway instead of one per AZ. Cheaper, but not highly available."
  default     = true
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster the subnets are tagged for, so the load balancer controller can discover them."
  default     = "workshop"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource."
  default = {
    Project   = "workshop"
    ManagedBy = "spacelift"
  }
}
