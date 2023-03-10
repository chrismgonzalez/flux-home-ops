variable "bucket_prefix" {
  type        = string
  description = "A prefix applied to the S3 bucket created to ensure a unique name."
  default     = "homeops-dev-use2"
}

variable "bucket_sse_algorithm" {
  type        = string
  description = "Encryption algorithm to use on the S3 bucket. Currently only AES256 is supported"
  default     = "AES256"
}

variable "assume_policy" {
  type        = map(string)
  description = "A map that allows you to specify additional AWS principles that will be added to the backend roles assume role policy"
  default     = {}
}
