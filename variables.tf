variable "project_id" {
  description = "Google Project ID."
  type        = string
}

//variable "state_bucket_name" {
//  description = "GCS Bucket name. Value should be unique ."
//  type        = string
//}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "europe-west3"
}

variable "instance-region" {
  description = "Google Cloud region"
  type        = string
  default     = "europe-west3-a"
}