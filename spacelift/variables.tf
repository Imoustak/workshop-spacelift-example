variable "repository_name" {
  type        = string
  description = "The name of the Git repository holding the infrastructure code."
  default     = "workshop"
}

variable "repository_branch" {
  type        = string
  description = "The branch the stacks track."
  default     = "main"
}

variable "tf_version" {
  type        = string
  description = "The OpenTofu version the stacks use."
  default     = "1.10.3"
}

variable "vcs" {
  type = object({
    type       = string
    enterprise = optional(bool, false)
    namespace  = optional(string)
    id         = optional(string)
    url        = optional(string)
  })
  description = "VCS integration the stacks source their code from."

  default = {
    type       = "GITHUB"
    enterprise = true
    namespace  = "eminalemdar"
    id         = "github-enterprise-default-integration"
  }
}

variable "aws_integration_id" {
  type        = string
  description = "The ID of the Spacelift AWS integration the stacks assume for cloud credentials."
  default     = "01HCY7118NC0NWCZ0QTJKK8WB7"
}
