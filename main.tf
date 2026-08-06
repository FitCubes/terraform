module "tf_backend" {
  source              = "./modules/remote_backend"
  backend_bucket_name = var.backend_bucket_name
}

module "frontend_bucket" {
  source               = "./modules/frontend_bucket"
  frontend_bucket_name = var.frontend_bucket_name
}

module "users" {
  source               = "./modules/users"
  frontend_bucket_name = var.frontend_bucket_name
  frontend_bucket_arn  = module.frontend_bucket.frontend_bucket_arn
}

module "compute" {
  source   = "./modules/compute"
  vpc_cidr = var.vpc_cidr
  vpc_name = var.vpc_name
}