###############################################################################################################################################################
#####        █████╗ ██╗      ██████╗  ██████╗ ██╗  ██╗██╗██╗   ██╗███████╗     ██╗  ██╗     ██████╗ ██╗      █████╗ ███╗   ██╗██╗  ██╗                    #####
#####       ██╔══██╗██║     ██╔════╝ ██╔═══██╗██║  ██║██║██║   ██║██╔════╝     ╚██╗██╔╝     ██╔══██╗██║     ██╔══██╗████╗  ██║██║ ██╔╝                    #####
#####       ███████║██║     ██║  ███╗██║   ██║███████║██║██║   ██║█████╗        ╚███╔╝      ██████╔╝██║     ███████║██╔██╗ ██║█████╔╝                     #####
#####       ██╔══██║██║     ██║   ██║██║   ██║██╔══██║██║╚██╗ ██╔╝██╔══╝        ██╔██╗      ██╔═══╝ ██║     ██╔══██║██║╚██╗██║██╔═██╗                     #####
#####       ██║  ██║███████╗╚██████╔╝╚██████╔╝██║  ██║██║ ╚████╔╝ ███████╗     ██╔╝ ██╗     ██║     ███████╗██║  ██║██║ ╚████║██║  ██╗                    #####
#####       ╚═╝  ╚═╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝     ╚═╝  ╚═╝     ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝                    #####
###############################################################################################################################################################
# Authors: Tristan Truckle & PLANK Team
# Version: 1.0
# Date: 15-01-2026
# Subject: Terraform AWS Infrastructure Deployment Project for AlgoHive x Plank
# Description:
# Notes :
###############################################################################################################################################################

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "public_subnet_count" {
  description = "Number of public subnets"
  type        = number
  default     = 3
}

variable "private_subnet_count" {
  description = "Number of private subnets"
  type        = number
  default     = 3
}

variable "availability_zones" {
  description = "List of availability zones for the subnets"
  type        = list(string)
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "tags" {
  description = "Common tags applied to subnet resources"
  type        = map(string)
  default     = {}
}
