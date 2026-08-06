output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = module.vpc.vpc_cidr_block
}

output "azs" {
  description = "Availability zones the subnets are spread across."
  value       = local.azs
}

output "public_subnets" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "IDs of the private subnets."
  value       = module.vpc.private_subnets
}

output "public_subnets_cidr_blocks" {
  description = "CIDR blocks of the public subnets."
  value       = module.vpc.public_subnets_cidr_blocks
}

output "private_subnets_cidr_blocks" {
  description = "CIDR blocks of the private subnets."
  value       = module.vpc.private_subnets_cidr_blocks
}

output "nat_public_ips" {
  description = "Public IPs of the NAT gateways."
  value       = module.vpc.nat_public_ips
}
