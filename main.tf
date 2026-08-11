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
  source                 = "./modules/compute"
  region                 = var.region
  vpc_cidr               = var.vpc_cidr
  vpc_name               = var.vpc_name
  subnets_public_cidrs   = var.subnets_public_cidrs
  subnets_database_cidrs = var.subnets_database_cidrs
  elasticache_cidrs      = var.elasticache_cidrs
  instance_type          = var.instance_type
  ami                    = var.ami
  public_key_path        = var.public_key_path
  user_data_path         = var.user_data_path
  postgres_password      = var.postgres_password
  postgres_username      = var.postgres_username
  postgres_db_name       = var.postgres_db_name
}
