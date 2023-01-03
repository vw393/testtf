variable "resource_name_prefix" {
  type        = string
  description = "Resource name prefix used for tagging and naming AWS resources."
}

variable "user_supplied_iam_role_name" {
  type        = string
  description = "(Optional) User-provided IAM role name for the instance profile."
  default     = null
}

variable "user_supplied_sg_ids" {
  type        = list(string)
  description = "(Optional) List of user-provided Security Group IDs for the server."
  default     = null
}

variable "permissions_boundary" {
  description = "(Optional) IAM Managed Policy to serve as permissions boundary for IAM Role."
  type        = string
  default     = null
}

variable "sm_secrets_arns" {
  type        = list(string)
  description = "(Optional) List of Secrets Manager ARNs of secrets the instance needs to access."
  default     = []
}

variable "buckets_access" {
  type        = list(string)
  description = "(Optional) List of S3 buckets the instance needs to access."
  default     = []
}

variable "lvm_vgs" {
  type        = map(any)
  description = "Map of maps with the specs of the LVM Volume Groups to configure."
}

variable "lvm_lvs" {
  type        = map(any)
  description = "Map of maps with the specs of the LVM Logical Volumes to configure."
}

variable "ami_id" {
  type        = string
  description = "AMI of instance (recommended Red Hat Enterprise Linux 8.0 HVM)."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the server will be deployed."
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where the server will be deployed."
}

variable "az" {
  type        = string
  description = "Availability zone where the server will be deployed."
}

variable "fqdn" {
  type        = string
  description = "FQDN of the server (hostname will be set by user_data)."
}

variable "inbound_access_rules" {
  type = list(object({
    name     = string
    port     = number
    protocol = string
    sgid     = string
    descr    = string
  }))
  description = "Map of access rules for SGs to access Oracle DB on well known ports."
  default     = []
}

variable "root_volume_type" {
  type        = string
  description = "Type of disk of root volume (gp2/gp3)."
  default     = "gp3"
}

variable "root_volume_size" {
  type        = number
  description = "Size in Gb of the root volume."
  default     = 12
}

variable "root_volume_tput" {
  type        = number
  description = "Throughput of root volume."
  default     = 150
}

variable "ssh_pubkeys" {
  type        = map(any)
  description = "Map of SSH public keys to grant access to the instance (ex. {\"user_foo\": \"....pubkey...\"})."
  default     = {}
}

variable "login_name" {
  type        = string
  description = "Admin user to configure."
  default     = "gtcadmin"
}