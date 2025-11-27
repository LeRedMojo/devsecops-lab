variable "admin_password" {
  description = "The password for the VM"
  type        = string
  sensitive   = true # This hides it from Terraform CLI output
}

variable "source_ip" {
  description = "My personal IP address for SSH access"
  type        = string
  sensitive   = true 
}

variable "username" {
  description = "Username for Azure"
  type        = string
  sensitive   = true
}