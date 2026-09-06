# tf-aws-stacks

Three independent Terraform stacks, built from shared modules, for a **private** AWS setup with no internet gateway:

| Stack | Builds | Apply order |
|---|---|---|
| `01-network` | VPC, 2 app + 2 db subnets across two AZs, internal route table, VPC endpoints (S3, Secrets Manager, SSM) | 1st |
| `02-database` | Secrets Manager secret (`rcadmin` / `changeme`), app + db security groups, DB subnet group, RDS **PostgreSQL 17** | 2nd |
| `03-compute` | IAM role, launch template with CRUD-website user data, Auto Scaling Group, one EC2 | 3rd |
| `04-database-restore` (optional) | New RDS restored from a snapshot of `demo-db`, with a fresh random password stored in a new secret | after 2 |
| `05-keycloak` (optional) | Keycloak 26 on existing VPC + RDS; sample realm `nifi` with an OIDC client and test user; credentials in Secrets Manager | after 2 |
| `06-nifi` (optional) | Apache NiFi 2 with OIDC login through that Keycloak realm | after 5 |

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
modules/{vpc,rds,rds_from_snapshot,launch_template,asg,ec2,
        keycloak_launch_template,nifi_launch_template}      reusable bricks
01-network/ 02-database/ 03-compute/         one state each; terraform.tfvars in each
scripts/aws-view.sh  scripts/aws-destroy.sh  AWS CLI fallbacks
scripts/upload-artifacts.sh                  stage Keycloak/NiFi tarballs in S3 (VPC has no internet)
TUTORIAL.md                                  step-by-step, line-by-line, with quizzes
TUTORIAL.docx / TUTORIAL.pdf                 the full book: every Terraform line and CLI script explained,
                                             analogies, best practices, gotchas, cloud-admin runbooks
COSTS.md                                     monthly/hourly price of every resource
```
