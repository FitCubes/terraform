# FitCubes Infrastructure

Terraform configuration that provisions the AWS infrastructure for the FitCubes application, plus the supporting Cloudflare DNS/CDN setup and the GitHub Actions secrets used by the frontend and backend repositories' CI/CD pipelines.

## Overview

The stack is split into seven modules, wired together from the root module (`main.tf`). At a high level it provisions:

- A VPC with public, database, and Elasticache subnets across multiple availability zones.
- An Auto Scaling Group of EC2 instances running the backend as a Docker container, fronted by an Application Load Balancer.
- A PostgreSQL database (RDS) and a Redis cluster (ElastiCache), both reachable only from the backend instances.
- An S3 bucket serving the frontend as a static website, restricted to Cloudflare's IP ranges.
- Cloudflare DNS records pointing at the ALB and the frontend bucket, plus a scoped API token used by CI to purge cache.
- CloudWatch log group, metrics, and an alarm driven by the CloudWatch Agent running on the backend instances.
- IAM users and scoped policies used by GitHub Actions to deploy the frontend and to trigger backend instance refreshes.
- GitHub Actions repository secrets, populated directly from Terraform outputs so the CI pipelines never need manual secret entry.
- An S3 backend (with native state locking) for Terraform's own state.

## Module layout

| Module | Path | Responsibility |
|---|---|---|
| `remote_backend` | `modules/remote_backend` | Creates the S3 bucket used to store Terraform state (separate from the backend block in `provider.tf`, which points at an already-existing bucket). |
| `frontend_bucket` | `modules/frontend_bucket` | S3 bucket configured as a static website, with a bucket policy that only allows `GetObject` from Cloudflare's published IP ranges. |
| `users` | `modules/users` | IAM users, policies, and access keys: one user with S3 read/write on the frontend bucket, one user allowed to start/cancel ASG instance refreshes. |
| `compute` | `modules/compute` | VPC, subnets, routing, security groups, RDS Postgres instance, ElastiCache Redis cluster, SSM parameters for app secrets, IAM role/instance profile, EC2 launch template and Auto Scaling Group, Application Load Balancer. |
| `github` | `modules/github` | Pushes AWS credentials, bucket name, region, Docker Hub credentials, and Cloudflare purge credentials as Actions secrets into the frontend and backend GitHub repositories. |
| `cloudflare` | `modules/cloudflare` | DNS CNAME records for the frontend and the ALB, a scoped "Cache Purge" API token, and a ruleset that disables caching for API traffic. |
| `cloudwatch` | `modules/cloudwatch` | CloudWatch log group for container logs and a metric alarm on CPU idle time, scoped to the backend ASG. |

## Networking

Defined in `modules/compute/network.tf`, inside the VPC (`var.vpc_cidr`, default `10.0.0.0/16`):

| Subnet group | Purpose | Internet access |
|---|---|---|
| `subnets_public_cidrs` | ALB and EC2 instances (backend) | Yes, via Internet Gateway |
| `subnets_database_cidrs` | RDS Postgres | No |
| `elasticache_cidrs` | ElastiCache Redis | No |

Security groups form a chain: the ALB security group accepts port 80 only from Cloudflare's IP ranges (`data.cloudflare_ip_ranges`), the backend security group accepts port 8080 only from the ALB security group, and the database/Redis security groups accept traffic only from the backend security group.

## Compute

- Backend instances run from a shared launch template (`aws_launch_template.backend`) inside an Auto Scaling Group (`asg_min_size` / `asg_max_size` / `asg_desired`, defaults 1/2/1).
- Instance user data installs Docker and the CloudWatch Agent, pulls application secrets (DB and Redis endpoints, JWT secret) from SSM Parameter Store at boot, and starts the backend container.
- The instance IAM role (`modules/compute/ec2_iam.tf`) is granted read access to the specific SSM parameters it needs, `AmazonSSMManagedInstanceCore`, and `CloudWatchAgentServerPolicy`.
- The CloudWatch Agent config explicitly sets `run_as_user` to `root`; without it, the agent runs as the low-privilege `cwagent` user, which cannot read Docker's container log files (`/var/lib/docker/containers/*/*-json.log`), owned by root with restrictive permissions.
- The ASG performs a rolling instance refresh (100-200% healthy percentage, auto rollback enabled) so new launch template versions roll out without downtime.
- Application secrets (DB credentials, Redis address, JWT secret) are written to SSM as `SecureString` parameters rather than passed through user data in plaintext.

## Requirements

- Terraform >= the version compatible with the pinned provider constraints below (see `.terraform.lock.hcl` for the exact resolved versions).
- AWS provider `~> 6.0`
- GitHub provider `~> 6.0`
- Cloudflare provider `~> 5`
- Credentials for all three providers: an AWS account with permissions to manage the resources above, a GitHub personal access token with repo-level Actions secret write access, and a Cloudflare API token scoped to the target zone.

## State backend

State is stored remotely in S3 (`provider.tf`):

```
bucket = "backendbucketfircubes18234"
key    = "terraform.tfstate"
region = "eu-north-1"
```

Locking uses S3's native conditional writes (`use_lockfile = true`), so no separate DynamoDB lock table is required. This bucket must exist before `terraform init` succeeds; the `remote_backend` module manages a differently-named bucket (`var.backend_bucket_name`) and is not what backs this configuration's own state.

## Configuration

All input variables are declared in `variables.tf`. Variables without a `default` are required and have no safe placeholder — they must be supplied via a `terraform.tfvars` file (gitignored) or environment variables (`TF_VAR_<name>`).

Required, sensitive:

- `postgres_password`, `postgres_username`, `postgres_db_name`
- `jwt_secret`
- `github_token`, `dockerhub_username`, `dockerhub_token`, `repository_name`
- `cloudflare_token`, `cloudflare_zone_id`

Required, not sensitive:

- `github_owner`
- `frontend_domain`, `backend_domain`

Everything else (region, VPC/subnet CIDRs, instance sizing, ASG capacity, log group and metrics namespace names) has a working default and only needs to be overridden to change behavior.

Never commit a populated `terraform.tfvars` — it is already listed in `.gitignore`.

## Usage

```
terraform init
terraform plan
terraform apply
```

Because the AWS, GitHub, and Cloudflare providers are all wired together in the root module, a `plan`/`apply` touches all three systems at once: infrastructure changes, DNS record changes, and repository secret updates happen from a single run.

## Outputs

Defined in `outputs.tf`:

- `frontend_bucket_link` — public website endpoint of the frontend S3 bucket.
- `frontend_bucket_user_access_key` / `frontend_bucket_user_access_key_secret` (sensitive) — credentials for the IAM user used to deploy frontend assets.
- `asg_refresh_access_key` / `asg_refresh_access_key_secret` (sensitive) — credentials for the IAM user used to trigger backend instance refreshes.
- `db_adress` — RDS Postgres endpoint address.
- `redis_node_adress` — ElastiCache Redis node address.
- `alb_domain` — DNS name of the backend Application Load Balancer.

## Notes

- The Cloudflare module's caching ruleset explicitly disables caching for the ALB hostname, so API responses are never served stale from Cloudflare's edge; only the frontend bucket traffic is proxied and cached normally.
- The frontend S3 bucket policy restricts `GetObject` to Cloudflare's current IP ranges rather than making the bucket unconditionally public, so the origin cannot be reached by bypassing Cloudflare directly.
- GitHub Actions secrets are provisioned by Terraform, not by hand, so rotating an IAM access key or the Cloudflare purge token and re-applying keeps the CI pipelines in sync automatically.
