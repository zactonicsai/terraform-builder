# Cost Breakdown, Resource by Resource

All prices are **us-east-1, on-demand, USD**, rounded, and assume a 730-hour month. AWS changes
prices, so treat these as estimates and confirm with the AWS Pricing Calculator
(https://calculator.aws) before relying on them. Last checked against public price lists in
September 2026.

**Free Tier:** accounts created before mid-July 2025 get the classic 12-month Free Tier
(750 hrs/month of t3.micro and db.t3.micro, 20 GB RDS storage, 30 GB EBS). Newer accounts get a
credit-based plan instead. Either way, the VPC interface endpoints are **never** free, and they
are the biggest line item below.

---

## Stack 1: `01-network`

| Resource | Terraform type | Count | Unit price | Monthly |
|---|---|---|---|---|
| VPC | `aws_vpc` | 1 | free | $0.00 |
| Subnets (app + db) | `aws_subnet` | 4 | free | $0.00 |
| Route table | `aws_route_table` | 1 | free | $0.00 |
| Route table associations | `aws_route_table_association` | 4 | free | $0.00 |
| Endpoint security group | `aws_security_group` | 1 | free | $0.00 |
| S3 gateway endpoint | `aws_vpc_endpoint` (Gateway) | 1 | free | $0.00 |
| Interface endpoints (secretsmanager, ssm, ssmmessages, ec2messages) | `aws_vpc_endpoint` (Interface) | 4 endpoints × 2 AZs = **8 ENIs** | $0.01 / ENI-hour | **$58.40** |
| Interface endpoint data processing | | | $0.01 / GB | ~$0.00 (demo traffic is tiny) |
| **Stack 1 total** | | | | **≈ $58.40** |

> The endpoints are placed in both app subnets (`subnet_ids = aws_subnet.app[*].id`), so each
> one costs 2 × $0.01/hr. Ways to cut this:
> - Remove `ssm`, `ssmmessages`, `ec2messages` from `interface_endpoints` if you never need a
>   shell or port-forward: saves $43.80, leaves $14.60 for Secrets Manager alone.
> - Put endpoints in only one subnet (single AZ): halves the cost, but a server in the other AZ
>   still resolves and reaches them (cross-AZ data at $0.01/GB).

---

## Stack 2: `02-database`

| Resource | Terraform type | Count | Unit price | Monthly |
|---|---|---|---|---|
| Secret | `aws_secretsmanager_secret` | 1 | $0.40 / secret-month | $0.40 |
| Secret version | `aws_secretsmanager_secret_version` | 1 | included | $0.00 |
| Secret API calls | | ~a few per server boot | $0.05 / 10,000 calls | ~$0.00 |
| App security group | `aws_security_group` | 1 | free | $0.00 |
| DB security group | `aws_security_group` | 1 | free | $0.00 |
| DB subnet group | `aws_db_subnet_group` | 1 | free | $0.00 |
| RDS PostgreSQL 17, db.t3.micro, Single-AZ | `aws_db_instance` | 1 | $0.018 / hour | $13.14 |
| RDS storage, 20 GB gp2 | (same resource) | 20 GB | $0.115 / GB-month | $2.30 |
| RDS automated backups | | up to 20 GB | free up to DB size | $0.00 |
| **Stack 2 total** | | | | **≈ $15.84** |

> Free Tier (classic) covers the db.t3.micro hours and the 20 GB, leaving only the $0.40 secret.
> Multi-AZ would double the instance and storage price; it is off here (`multi_az` not set).

---

## Stack 3: `03-compute`

| Resource | Terraform type | Count | Unit price | Monthly |
|---|---|---|---|---|
| IAM role, policy, attachment, instance profile | `aws_iam_*` | 4 | free | $0.00 |
| Launch template | `aws_launch_template` | 1 | free | $0.00 |
| Auto Scaling Group (the group itself) | `aws_autoscaling_group` | 1 | free | $0.00 |
| ASG instance, t3.micro | (launched by ASG) | 1 (desired_capacity) | $0.0104 / hour | $7.59 |
| ASG instance root disk, 8 GB gp3 | (launched by ASG) | 1 | $0.08 / GB-month | $0.64 |
| Standalone EC2, t3.micro | `aws_instance` | 1 | $0.0104 / hour | $7.59 |
| Standalone EC2 root disk, 8 GB gp3 | (same resource) | 1 | $0.08 / GB-month | $0.64 |
| Session Manager sessions / port forwarding | | any | free | $0.00 |
| SSM parameter lookup (AMI) | `data.aws_ssm_parameter` | reads | free | $0.00 |
| **Stack 3 total** | | | | **≈ $16.46** |

> If the ASG scales to `max_size = 2`, add another $8.23/month while the second server runs.
> Free Tier (classic) covers 750 t3.micro hours, i.e. roughly one of the two servers.

---

## Optional Stack 4: `04-database-restore`

| Resource | Terraform type | Count | Unit price | Monthly |
|---|---|---|---|---|
| Snapshot lookup | `data.aws_db_snapshot` | reads | free | $0.00 |
| Random password | `random_password` | 1 | free (local only) | $0.00 |
| DB subnet group | `aws_db_subnet_group` | 1 | free | $0.00 |
| Restored RDS PostgreSQL, db.t3.micro | `aws_db_instance` | 1 | $0.018 / hour | $13.14 |
| Restored storage, 20 GB (size comes from the snapshot) | (same resource) | 20 GB | $0.115 / GB-month | $2.30 |
| New secret | `aws_secretsmanager_secret` | 1 | $0.40 / secret-month | $0.40 |
| Manual snapshot `demo-db-snap-1` (made with the CLI, kept until you delete it) | outside Terraform | ~1 GB actual data | $0.095 / GB-month | ~$0.10 |
| **Stack 4 total** | | | | **≈ $15.94** (+ the snapshot while it exists) |

> This is a second full database, so it roughly doubles Stack 2. Free Tier covers only 750
> db.t3.micro hours total, so running two databases exceeds it. Manual snapshots are billed on
> actual data used, not the 20 GB allocated, and they are **not** deleted by `terraform destroy`.

---

## Optional Stack 5: `05-keycloak`

| Resource | Terraform type | Count | Unit price | Monthly |
|---|---|---|---|---|
| Three random passwords | `random_password` | 3 | free | $0.00 |
| Secret | `aws_secretsmanager_secret` | 1 | $0.40 / secret-month | $0.40 |
| Security group, IAM role/policy/profile, launch template | various | 6 | free | $0.00 |
| Keycloak EC2, t3.small (2 GB RAM; Keycloak needs more than a micro) | `aws_instance` | 1 | $0.0208 / hour | $15.18 |
| Root disk, 8 GB gp3 | (same) | 1 | $0.08 / GB-month | $0.64 |
| Extra RDS storage for the `keycloak` database | none (inside existing RDS) | ~50 MB | within the 20 GB | $0.00 |
| **Stack 5 total** | | | | **≈ $16.22** |

## Optional Stack 6: `06-nifi`

| Resource | Terraform type | Count | Unit price | Monthly |
|---|---|---|---|---|
| Two random passwords | `random_password` | 2 | free | $0.00 |
| Security group, IAM role/policy/profile, launch template | various | 6 | free | $0.00 |
| NiFi EC2, t3.medium (4 GB RAM; NiFi 2 wants at least 2 GB heap) | `aws_instance` | 1 | $0.0416 / hour | $30.37 |
| Root disk, 8 GB gp3 | (same) | 1 | $0.08 / GB-month | $0.64 |
| **Stack 6 total** | | | | **≈ $31.01** |

## One-time: artifact bucket (`scripts/upload-artifacts.sh`)

| Item | Unit price | Monthly |
|---|---|---|
| S3 storage, ~0.6 GB (Keycloak ~0.2 GB + NiFi ~0.4 GB) | $0.023 / GB-month | ~$0.01 |
| S3 GET through the gateway endpoint | $0.0004 / 1,000 requests | ~$0.00 |
| Data from S3 to EC2 in the same region via gateway endpoint | free | $0.00 |

> Neither t3.small nor t3.medium is Free-Tier eligible; these two stacks are the priciest
> compute in the project. Stop the instances (`aws ec2 stop-instances`) between sessions to pay
> only for disks.

---

## Grand Total

| | Monthly | Hourly (useful for short practice sessions) |
|---|---|---|
| Stack 1 network | $58.40 | $0.080 |
| Stack 2 database | $15.84 | $0.022 |
| Stack 3 compute | $16.46 | $0.023 |
| **All three, no Free Tier** | **≈ $90.70** | **≈ $0.125** |
| Optional Stack 4 restore, while it exists | +$15.94 | +$0.022 |
| Optional Stack 5 Keycloak | +$16.22 | +$0.022 |
| Optional Stack 6 NiFi | +$31.01 | +$0.042 |
| **Everything (1-6), no Free Tier** | **≈ $153.90** | **≈ $0.211** |
| **All three, classic Free Tier** | **≈ $59.50** | **≈ $0.082** |
| Network with only the `secretsmanager` endpoint, Free Tier | ≈ $15.60 | ≈ $0.021 |

A two-hour practice session costs about **25 cents** at full price. Leaving it running for a month
costs about **$90**. Destroy in reverse order (03 → 02 → 01) when you finish.

---

## Charges that are NOT in the tables (and why)

| Item | Why it is excluded |
|---|---|
| Data transfer out to the internet | There is no internet gateway; nothing can leave |
| NAT Gateway ($0.045/hr + $0.045/GB) | Not built; the endpoints replace it |
| Load balancer (~$16/month + LCU) | Not built in this version |
| Cross-AZ data transfer ($0.01/GB each direction) | App-to-DB traffic crosses AZs only if the ASG lands a server in AZ b; pennies at demo volume |
| CloudWatch | Only default free metrics are used; no custom metrics or alarms |
| Snapshots | `skip_final_snapshot = true`; automated backups are within the free allowance |
| Terraform itself | Open source, no charge |

---

## Cheapest Way to Learn

1. Apply all three stacks, do the tutorial, destroy the same day: **well under $1**.
2. Keep Stack 1 up between sessions but drop the three `ssm*` endpoints: **~$15/month**.
3. Never keep Stack 2 and 3 up overnight unless you are on Free Tier and have checked your usage.
4. Set a **billing alarm** in the AWS console (Billing → Budgets) for $10/month; it is free and
   emails you before a forgotten stack becomes expensive.
