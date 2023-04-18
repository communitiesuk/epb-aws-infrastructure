variable "app_name" {
  description = "name of the app file name downloaded from existing infrastructure"
  default     = "ccxml"
  type        = string
}

variable "bucket" {
  description = "The bucket that will contain the feed"
  default     = "epbr-cc-tray"
  type        = string
}

variable "key" {
  description = "The key within the bucket that will contain the feed"
  default     = "cc.xml"
  type        = string
}


variable "region" {
  type = string
}

