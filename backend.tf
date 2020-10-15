terraform {
  backend "gcs" {
    bucket  = "tf-state-gik"
    prefix  = "gik"
    credentials = "gik-shop-0bc5c4ec1b82.json"
  }
}