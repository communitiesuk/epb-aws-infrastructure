variable "app_name" {
  description = "name of the app file name downloaded from existing infrastructure"
  default     = "ccxml"
}

variable "bucket" {
  description = "The bucket that will contain the feed"
  default = "epbr-cc-tray"
}

variable "key" {
  description = "The key within the bucket that will contain the feed"
  default     = "cc.xml"
}


variable "region" {
  type = string
}

