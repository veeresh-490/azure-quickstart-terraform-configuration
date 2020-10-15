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
variable "virtualMachineAdminUserName" {
  type        = string
  description = "Administrator Username for the local admin account"
  default     = "cloudguy"
}

variable "virtualMachineAdminPassword" {
  type        = string
  description = "Administrator password for the local admin account"
  default     = "Abcd@1234"
}

variable "virtualMachineNamePrefix" {
  type        = string
  description = "Name of the virtual machine to be created"
  default     = "MyVM0"
  validation {
    condition     = length(var.virtualMachineNamePrefix) <= 15
    error_message = "String length should be less than 15."
  }
}

variable "virtualMachineCount" {
  description = "Number of  virtual machines to be created"
  default     = 3
}

variable "virtualMachineSize" {
  type        = string
  description = "Virtual Machine Size"
  default     = "Standard_DS2_v2"
  validation {
    condition     = contains(["Standard_DS1_v2", "Standard_DS2_v2", "Standard_DS3_v2", "Standard_DS4_v2", "Standard_DS5_v2"], var.virtualMachineSize)
    error_message = "Accepted value for \"virtualMachineSize\" are \"Standard_DS1_v2\",\"Standard_DS2_v2\",\"Standard_DS3_v2\",\"Standard_DS4_v2\", \"Standard_DS5_v2\"."
  }
}

variable "operatingSystem" {
  type        = string
  description = "Operating System of the Server"
  default     = "Server2019"
  validation {
    condition     = contains(["Server2012R2", "Server2016", "Server2019"], var.operatingSystem)
    error_message = "Accpeted values for \"operatingSystem\" are \"Server2012R2\",\"Server2016\",\"Server2019\"."
  }
}

variable "location" {
  type        = string
  description = "Location for all resources."
  default     = "westus"
}

variable "availabilitySetName" {
  type        = string
  description = "Availability Set Name where the VM will be placed"
  default     = "MyAvailabilitySet"
}

variable "dnsPrefixForPublicIP" {
  type        = string
  description = "Globally unique DNS prefix for the Public IPs used to access the Virtual Machines"
  default     = "demo"
  validation {
    condition     = length(var.dnsPrefixForPublicIP) <= 15
    error_message = "Accpeted values for \"operatingSystem\" are \"Server2012R2\",\"Server2016\",\"Server2019\"."
  }
}
