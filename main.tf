module "tf_backend" {
  source              = "./modules/remote_backend"
  backend_bucket_name = var.backend_bucket_name
}

module "frontend_bucket" {
  source               = "./modules/frontend_bucket"
  frontend_bucket_name = var.frontend_bucket_name
}

module "users" {
  source              = "./modules/users"
  frontend_bucket_arn = module.frontend_bucket.frontend_bucket_arn
}

module "compute" {
  source                 = "./modules/compute"
  region                 = var.region
  vpc_cidr               = var.vpc_cidr
  vpc_name               = var.vpc_name
  subnets_public_cidrs   = var.subnets_public_cidrs
  subnets_database_cidrs = var.subnets_database_cidrs
  elasticache_cidrs      = var.elasticache_cidrs
  frontend_domain        = var.frontend_domain
  postgres_password      = var.postgres_password
  postgres_username      = var.postgres_username
  postgres_db_name       = var.postgres_db_name
  jwt_secret             = var.jwt_secret

  instance_type = var.instance_type

  log_group_lamdba_smoke = var.log_group_lambda_smoke

  repository_name = var.repository_name
}


module "github" {
  source                        = "./modules/github"
  aws_access_key                = module.users.frontend_bucket_user_access_key
  aws_access_key_secret         = module.users.frontend_bucket_user_access_key_secret
  aws_region                    = var.region
  frontend_s3_bucket            = var.frontend_bucket_name
  asg_resresh_access_key        = module.users.asg_refresh_access_key
  asg_refresh_access_key_secret = module.users.asg_refresh_access_key_secret
  dockerhub_token               = var.dockerhub_token
  dockerhub_username            = var.dockerhub_username
  repository_name               = var.repository_name
  backend_domain                = var.backend_domain
  cloudflare_purge_token        = module.clodflare.cache_purge_token
  cloudflare_zone_id            = var.cloudflare_zone_id
}

module "clodflare" {
  source                 = "./modules/cloudflare"
  frontent_bucket_domain = module.frontend_bucket.frontend_link
  cloudflare_zone_id     = var.cloudflare_zone_id
  alb_domain             = module.compute.alb_domain
}

module "coudwatch" {
  source                 = "./modules/cloudwatch"
  vpc_name               = var.vpc_name
  db_instance_identifier = module.compute.db_instance_identifier
  alert_email            = var.alert_email
}
