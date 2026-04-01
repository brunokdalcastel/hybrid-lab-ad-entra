variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "brazilsouth"

  validation {
    condition     = can(regex("^[a-z]+$", var.location))
    error_message = "Location must be a valid Azure region in lowercase without spaces."
  }
}

variable "environment" {
  description = "Environment tag (lab, dev, staging, prod)"
  type        = string
  default     = "lab"

  validation {
    condition     = contains(["lab", "dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: lab, dev, staging, prod."
  }
}

variable "project" {
  description = "Project name used in tags and naming"
  type        = string
  default     = "hybrid-lab"
}

variable "vnet_address_space" {
  description = "Address space for the hub VNet"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for the default subnet"
  type        = list(string)
  default     = ["10.1.1.0/24"]
}

variable "log_analytics_retention_days" {
  description = "Retention in days for Log Analytics Workspace (30 = free tier)"
  type        = number
  default     = 30

  validation {
    condition     = var.log_analytics_retention_days >= 30 && var.log_analytics_retention_days <= 730
    error_message = "Retention must be between 30 and 730 days."
  }
}
