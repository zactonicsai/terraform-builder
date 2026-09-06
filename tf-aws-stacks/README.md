# tf-aws-stacks

Three independent Terraform stacks, built from shared modules, for a **private** AWS setup with no internet gateway:

| Stack | Builds | Apply order |
|---|---|---|
| `01-network` | VPC, 2 app + 2 db subnets across two AZs, internal route table, VPC endpoints (S3, Secrets Manager, SSM) | 1st |
| `02-database` | Secrets Manager secret (`rcadmin` / `changeme`), app + db security groups, DB subnet group, RDS **PostgreSQL 17** | 2nd |
| `03-compute` | IAM role, launch template with CRUD-website user data, Auto Scaling Group, one EC2 | 3rd |
| `04-database-restore` (optional) | New RDS restored from a snapshot of `demo-db`, with a fresh random password stored in a new secret | after 2 |

Stacks find each other by tags and names via `data` blocks; no shared state.

## Quick start

```bash
(cd 01-network  && terraform init && terraform apply)
(cd 02-database && terraform init && terraform apply)   # ~10 min
(cd 03-compute  && terraform init && terraform apply)
```

Wait 3-4 minutes, then open a tunnel and browse to http://localhost:8080:

```bash
cd 03-compute && eval "$(terraform output -raw port_forward_command)"
```

Requires the AWS CLI Session Manager plugin. Destroy in reverse: 03, 02, 01.

## Layout

```
modules/{vpc,rds,rds_from_snapshot,launch_template,asg,ec2}   reusable bricks
01-network/ 02-database/ 03-compute/         one state each; terraform.tfvars in each
scripts/aws-view.sh  scripts/aws-destroy.sh  AWS CLI fallbacks
TUTORIAL.md                                  step-by-step, line-by-line, with quizzes
COSTS.md                                     monthly/hourly price of every resource
```
