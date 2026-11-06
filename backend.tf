# The state is the object chrisguidry.tfstate in a Linode Object Storage
# bucket. Terraform reads the bucket's access key from AWS_ACCESS_KEY_ID
# and AWS_SECRET_ACCESS_KEY. Linode speaks S3 but is not AWS, so the
# checks that only AWS answers are skipped.
terraform {
  backend "s3" {
    bucket       = "guidry-github-settings-state"
    key          = "chrisguidry.tfstate"
    region       = "us-east-1"
    use_lockfile = true

    endpoints = {
      s3 = "https://us-east-1.linodeobjects.com"
    }

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
}
