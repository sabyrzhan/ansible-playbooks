variable "region" {
  type = string
  description = "AWS region"
}

variable "volume_size" {
  type = number
  description = "Voume size in GB"
}

variable "instance_type" {
  type = string
  description = "Instance type"
}