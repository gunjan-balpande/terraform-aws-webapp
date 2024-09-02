variable "region" {
  description = "The AWS region to deploy resources in"
  default     = "us-west-2"
}

variable "your_ip" {
  description = "Your IP address for SSH access"
  type        = string
}
