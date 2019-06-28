# Provider variables
variable "provider_region" {
  type        = "string"
  description = "Region used by terraform aws provider."
}

variable "provider_profile" {
  type        = "string"
  default     = "default"
  description = "Profile of AWS credentials file to use"
}