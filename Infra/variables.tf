variable "admin_password" {
  description = "The password for the VM"
  type        = string
  sensitive   = true 
}

variable "source_ip" {
  description = "My personal IP address for SSH access"
  type        = string
  sensitive   = true 
}

variable "username" {
  description = "Username for VM"
  type        = string
  sensitive   = true
}