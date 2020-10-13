# Variable declaration
variable "tf_var_arm_subscription_id" {
  description = "enter subscription id"
}

variable "tf_var_arm_client_id" {
  description = "Enter Client ID"
}

variable "tf_var_arm_client_secret" {
  description = "Enter secret"
}

variable "tf_var_arm_tenant_id" {
  description = "Enter tenant ID"
}

variable "resourceGroupName" {
  type        = string
  description = "Resource grou name"
  default     = "terraform-rg"
}
variable "adminUsername" {
  type        = string
  description = "Admin username for VM"
  default     = "cloudguy"
}

variable "numberOfInstances" {
  description = "Number of VMs to deploy, limit 5 since this sample is using a single storage account"
  default     = 2
  validation {
    condition     = contains(range(2, 5 + 1), var.numberOfInstances)
    error_message = "Number of VMs to deploy accepts the values ranges from 2 to 5."
  }
}

variable "OS" {
  type        = string
  description = "OS Platform for the VM"
  default     = "Ubuntu"
  validation {
    condition     = var.OS == "Ubuntu" || var.OS == "Windows"
    error_message = "OS platform either \"Ubuntu\",\"Windows\"."
  }
}

variable "location" {
  type        = string
  description = "Location for all resources."
  default     = "westus"
}

variable "authenticationType" {
  type        = string
  description = "Type of authentication to use on the Virtual Machine. SSH key is recommended."
  default     = "sshPublicKey"
  validation {
    condition     = var.authenticationType == "sshPublicKey" || var.authenticationType == "password"
    error_message = "Authentication type should be either \"sshPublicKey\",\"password\"."
  }
}

variable "adminPassword" {
  type        = string
  description = "password for the Virtual Machine."
  default     = "Abcd@1234"
}

variable "vmSize" {
  type        = string
  description = "size of the Vm"
  default     = "Standard_A1_v2"
}
