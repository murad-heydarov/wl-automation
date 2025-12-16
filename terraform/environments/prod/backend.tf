# terraform/environments/prod/backend.tf

# terraform {
#   backend "s3" {
#     bucket         = "terraform-state-marktech"
#     key            = "wl-automation/terraform.tfstate"
#     region         = "eu-central-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#   }
# }
