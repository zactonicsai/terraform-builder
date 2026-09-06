# Terraform on AWS in Three Stacks: Private Network, PostgreSQL 17, and a CRUD Website

*A beginner tutorial written so anyone, including a middle schooler, can follow it.*

---

## Table of Contents

1. [What Are We Building?](#1-what-are-we-building)
2. [Why Three Separate Stacks?](#2-why-three-separate-stacks)
3. [Step-by-Step: Build It](#3-step-by-step-build-it)
4. [Step-by-Step: Use the Website](#4-step-by-step-use-the-website)
5. [Step-by-Step: Tear It Down](#5-step-by-step-tear-it-down)
6. [Background: Terraform in Five Minutes](#6-background-terraform-in-five-minutes)
7. [Background: The AWS Pieces](#7-background-the-aws-pieces)
8. [Project Layout](#8-project-layout)
9. [Line-by-Line: Stack 1, Network](#9-line-by-line-stack-1-network)
10. [Line-by-Line: Stack 2, Database](#10-line-by-line-stack-2-database)
11. [Line-by-Line: Stack 3, Compute](#11-line-by-line-stack-3-compute)
12. [Line-by-Line: The Website Script](#12-line-by-line-the-website-script)
13. [Optional Stack 4: Restore a Database from a Snapshot](#13-optional-stack-4-restore-a-database-from-a-snapshot)
14. [Backup AWS CLI Commands](#14-backup-aws-cli-commands)
15. [Best Practices, Pros and Cons](#15-best-practices-pros-and-cons)
16. [Quiz Answer Key](#16-quiz-answer-key)

---

## 1. What Are We Building?

Picture a walled town with **no front gate**. Nothing from the outside can drive in, and nothing
inside can drive out. The only way to talk to the outside world is through a few guarded
side-doors that lead straight to specific AWS offices.

```
          (no internet gateway - the wall has no gate)
   +-----------------------------------------------------------+
   |                      VPC 10.0.0.0/16                       |
   |                                                           |
   |   App street (AZ-a)          App street (AZ-b)            |
   |   +---------------------+    +---------------------+      |
   |   | EC2   (website)     |    |                     |      |
   |   | ASG   (website x1+) |    | ASG (grows here)    |      |
   |   | [side-doors] -------+----+--> Secrets Manager, SSM    |
   |   +---------------------+    +---------------------+      |
   |                                                           |
   |   DB street (AZ-a)           DB street (AZ-b)             |
   |   +---------------------+    +---------------------+      |
   |   | RDS PostgreSQL 17   |    | (standby space)     |      |
   |   +---------------------+    +---------------------+      |
   |                                                           |
   |   [S3 side-door] ---> Amazon Linux package repo            |
   +-----------------------------------------------------------+
        ^
        | You get in with AWS Session Manager (no SSH, no public IP)
```

- **Stack 1 (network):** VPC, two app subnets, two db subnets, one internal route table, and
  the side-doors (VPC endpoints). No internet gateway at all.
- **Stack 2 (database):** a secret holding `rcadmin` / `changeme`, the security group the app
  servers will wear, the security group for the database, and RDS **PostgreSQL 17**.
- **Stack 3 (compute):** a launch template with a first-boot script that installs a tiny
  **Notes** website (Create, Read, Update, Delete against the database), an Auto Scaling Group
  built from it, and one standalone EC2 built from it.

---

## 2. Why Three Separate Stacks?

Each folder (`01-network`, `02-database`, `03-compute`) is its own Terraform project with its
own state file. You `apply` them in order and `destroy` them in reverse.

| Pro | Con |
|---|---|
| Blast radius: a mistake in compute cannot delete your database | Three `init`/`apply` commands instead of one |
| Different speeds: the network rarely changes, compute changes daily | Stacks must find each other (we use tag lookups) |
| Different owners: a network team, a DBA, an app team | You must remember the order |
| Smaller plans that are easier to read | |

**How stacks find each other:** Stack 1 tags its subnets `Tier = app` and `Tier = db`. Stack 2
and 3 use `data` blocks to *look up* those resources by tag or name. No state files are shared,
so any stack can be re-applied without touching the others.

### Quiz 1

1. In which order do you apply the stacks? In which order do you destroy them?
2. How does Stack 3 know which VPC to use if it never reads Stack 1's state file?

---

## 3. Step-by-Step: Build It

### What you need

| Tool | Check |
|---|---|
| AWS account + credentials | `aws sts get-caller-identity` |
| AWS CLI v2 | `aws --version` |
| **Session Manager plugin** for the CLI (to reach the servers) | `session-manager-plugin --version` |
| Terraform 1.5+ | `terraform version` |

Install the Session Manager plugin from the AWS docs page "Install the Session Manager plugin
for the AWS CLI" if the check fails. It is a one-time download.

### Step 1: Stack 1, the network

```bash
cd 01-network
terraform init
terraform plan
terraform apply       # type yes. About 3 minutes (endpoints are the slow part).
cd ..
```

Terraform prints `vpc_id`, `app_subnet_ids`, `db_subnet_ids`.

### Step 2: Stack 2, the database

```bash
cd 02-database
terraform init
terraform plan        # you should see the data lookups find your VPC
terraform apply       # type yes. About 8 to 12 minutes; RDS is slow.
cd ..
```

Outputs: `rds_endpoint`, `secret_arn`, `app_sg_id`.

Check the secret landed:

```bash
aws secretsmanager get-secret-value --secret-id demo/db-credentials \
  --query SecretString --output text
# {"username":"rcadmin","password":"changeme","dbname":"appdb","port":5432}
```

### Step 3: Stack 3, the servers

```bash
cd 03-compute
terraform init
terraform plan
terraform apply       # type yes. About 2 minutes.
```

Outputs: `ec2_instance_id`, `ec2_private_ip`, `asg_name`, and a ready-made
`port_forward_command`.

Give the servers **3 to 4 minutes** after apply to run their first-boot script.

### Quiz 2

1. Which stack takes the longest and why?
2. What does `terraform plan` in Stack 2 do *before* it plans any new resources?

---

## 4. Step-by-Step: Use the Website

There is no public IP and no internet gateway, so you cannot just open a browser. Instead you
open a private tunnel with **Session Manager port forwarding**, which works through the SSM
side-doors Stack 1 built.

### Step 1: Open the tunnel

Copy the `port_forward_command` output, or:

```bash
cd 03-compute
eval "$(terraform output -raw port_forward_command)"
```

You will see `Waiting for connections...`. Leave this terminal open.

### Step 2: Open the site

In your browser go to **http://localhost:8080**. You should see **"Notes (stored in RDS
PostgreSQL)"** with an input box.

- Type a note and press **Add** (Create)
- The list refreshes from the database (Read)
- Edit the text and press **Save** (Update)
- Press **Delete** (Delete)

### Step 3: Prove it is really in the database

Open a second terminal and log in to the server (no SSH key, no password):

```bash
aws ssm start-session --target $(cd 03-compute && terraform output -raw ec2_instance_id)
```

Then on the server:

```bash
sudo dnf install -y postgresql17
SECRET=$(aws secretsmanager get-secret-value --secret-id demo/db-credentials --region us-east-1 --query SecretString --output text)
export PGPASSWORD=$(echo "$SECRET" | python3 -c 'import sys,json;print(json.load(sys.stdin)["password"])')
psql -h $(grep DB_HOST /opt/app/app.env | cut -d= -f2) -U rcadmin -d appdb -c 'SELECT * FROM notes;'
```

You will see the rows you typed in the browser. Type `exit` to leave.

### If it does not work

| Symptom | Check |
|---|---|
| `TargetNotConnected` | Wait 2 more minutes; then `./scripts/aws-view.sh` and look at the SSM section |
| Page never loads | On the server: `sudo systemctl status app` and `sudo journalctl -u app -n 50` |
| `could not connect to server` | The DB security group must allow the app security group (Stack 2) |

### Quiz 3

1. Why can't you open the website with the server's IP address from your laptop?
2. Which AWS feature gives you a terminal on the server without SSH?

---

## 5. Step-by-Step: Tear It Down

Reverse order, always. Otherwise AWS refuses ("this VPC still has things in it").

```bash
cd 03-compute  && terraform destroy && cd ..
cd 02-database && terraform destroy && cd ..
cd 01-network  && terraform destroy && cd ..
```

> **Cost note:** the four interface endpoints are placed in both AZs, so they cost about $0.08
> per hour together (about $58 per month). RDS db.t3.micro and t3.micro EC2 are Free-Tier
> eligible. See `COSTS.md` for a resource-by-resource breakdown. Do not leave this running for weeks.

---

## 6. Background: Terraform in Five Minutes

Terraform builds cloud resources from **text files** instead of clicking through the AWS website.
This is **Infrastructure as Code**.

| Word | Meaning |
|---|---|
| **Provider** | The plugin that talks to a cloud (`aws`) |
| **Resource** | One thing to create: `resource "aws_vpc" "this" { ... }` |
| **Data source** | One thing to *look up* that already exists: `data "aws_vpc" "this" { ... }` |
| **Variable** | A knob: `var.instance_type` |
| **Local** | A value you compute once and reuse: `local.user_data` |
| **Output** | A value printed at the end: the RDS endpoint |
| **Module** | A reusable folder of resources (a LEGO brick) |
| **State** | `terraform.tfstate`, the memory of what was built. Never delete it |

Referencing: `aws_vpc.this.id` (a resource), `data.aws_vpc.this.id` (a data source),
`var.name` (a variable), `module.vpc.vpc_id` (a module output), `local.x` (a local).

The workflow: `init` (download plugins) → `plan` (preview) → `apply` (build) → `destroy` (remove).

### Quiz 4

1. What is the difference between `resource` and `data`?
2. How do you reference the output `vpc_id` from a module called `vpc`?

---

## 7. Background: The AWS Pieces

| Piece | Everyday comparison | What it really is |
|---|---|---|
| **VPC** | Walled town | A private network with an IP range |
| **Subnet** | A street | A smaller IP range in one AZ |
| **Availability Zone** | A separate building with its own power | Physically separate data center |
| **Route table** | Road signs | Where traffic may go. Ours only has `local` |
| **Internet Gateway** | The town gate | We do **not** build one |
| **VPC Endpoint** | A guarded side-door to one AWS office | Private link to an AWS service |
| Gateway endpoint (S3) | Free side-door | A route-table entry; no network card |
| Interface endpoint | Side-door with a doorman ($) | A network card in your subnet with a private IP |
| **Security group** | Bouncer at a door | Firewall rules on a resource |
| **Secrets Manager** | Locked safe | Stores the DB username/password |
| **RDS** | Librarian | Managed PostgreSQL |
| **DB subnet group** | The two streets the library may use | RDS needs 2 AZs |
| **IAM role + instance profile** | Employee badge on a lanyard | Permissions a server carries |
| **Launch template** | Recipe card | AMI, size, badge, bouncer, first-boot script |
| **User data** | First-day to-do list | Script that runs once at first boot |
| **Auto Scaling Group** | Manager who hires/fires | Keeps N servers from the recipe running |
| **EC2** | A rented computer | A virtual server |
| **Session Manager (SSM)** | Intercom into the building | Shell access with no SSH/public IP |

### CIDR in one minute

`10.0.0.0/16` = every address starting `10.0.` (65,536). `10.0.1.0/24` = every address starting
`10.0.1.` (256). Bigger number after `/` = smaller group.

### Quiz 5

1. What is the difference between a gateway endpoint and an interface endpoint?
2. Which two things are missing from this VPC that a "normal" web VPC has?

---

## 8. Project Layout

```
tf-aws-stacks/
├── modules/                    # reusable bricks
│   ├── vpc/                    # VPC, subnets, route table, endpoints
│   ├── rds/                    # secret, app SG, db SG, subnet group, PostgreSQL
│   ├── rds_from_snapshot/      # restore a DB from a snapshot, new random password in Secrets Manager
│   ├── launch_template/        # IAM role, launch template, user_data.sh.tpl
│   ├── asg/                    # auto scaling group
│   └── ec2/                    # one instance from the template
├── 01-network/                 # STACK 1  (own state)
│   ├── versions.tf  variables.tf  main.tf  outputs.tf  terraform.tfvars
├── 02-database/                # STACK 2  (own state)
│   ├── versions.tf  variables.tf  data.tf  main.tf  outputs.tf  terraform.tfvars
├── 03-compute/                 # STACK 3  (own state)
│   ├── versions.tf  variables.tf  data.tf  main.tf  outputs.tf  terraform.tfvars
│   └── custom_user_data.sh.tpl # example first-boot override
├── 04-database-restore/        # STACK 4, optional: new DB from a snapshot + new password
├── scripts/
│   ├── aws-view.sh             # CLI: see everything
│   └── aws-destroy.sh          # CLI: emergency teardown
├── COSTS.md                    # price of every resource
└── TUTORIAL.md
```

Every stack has the same `versions.tf`:

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
provider "aws" {
  region = var.region
  default_tags {
    tags = { Project = var.project_name, ManagedBy = "terraform" }
  }
}
```
`default_tags` puts `Project = demo` on everything. The backup CLI scripts search by that tag.

---

## 9. Line-by-Line: Stack 1, Network

### 01-network/main.tf

```hcl
module "vpc" {
  source = "../modules/vpc"
  name                = var.project_name
  region              = var.region
  vpc_cidr            = var.vpc_cidr
  azs                 = var.azs
  app_subnet_cidrs    = var.app_subnet_cidrs
  db_subnet_cidrs     = var.db_subnet_cidrs
  interface_endpoints = var.interface_endpoints
}
```
"Use the brick in `../modules/vpc` and pass it these settings." Note `../`: modules live one
level up so all three stacks can share them.

### modules/vpc/main.tf

```hcl
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}
```
The town. DNS must be on for two reasons: RDS hands out a hostname, and interface endpoints
use "private DNS" so that `secretsmanager.us-east-1.amazonaws.com` resolves to the side-door
instead of the internet.

```hcl
resource "aws_subnet" "app" {
  count             = length(var.app_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.app_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags = { Name = "${var.name}-app-${count.index + 1}", Tier = "app" }
}
```
`count` makes one subnet per CIDR in the list; `count.index` is 0 then 1, so subnet 0 lands in
AZ a and subnet 1 in AZ b. **The `Tier = "app"` tag is how Stack 3 will find these later.**
There is no `map_public_ip_on_launch`: nothing here gets a public IP.

```hcl
resource "aws_subnet" "db" { ... Tier = "db" }
```
Same idea for the database streets. Stack 2 searches for `Tier = "db"`.

```hcl
resource "aws_route_table" "internal" {
  vpc_id = aws_vpc.this.id
}
```
A route table with **no `route` blocks**. AWS adds one automatic route called `local`
(10.0.0.0/16 → stay inside). Because there is no `0.0.0.0/0` route and no gateway, packets
addressed to the internet have nowhere to go. That is what "manual only within VPC" means.

```hcl
resource "aws_route_table_association" "app" {
  count          = length(aws_subnet.app)
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.internal.id
}
```
Nail the same road sign onto every app street; the `db` block does the same for db streets.

```hcl
resource "aws_security_group" "endpoints" {
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
}
```
The doorman at each side-door: allow HTTPS (443) from anyone inside the town.

```hcl
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.internal.id]
}
```
The free S3 side-door. It works by adding a special route to our route table. Amazon Linux keeps
its package repositories in S3, so this single line is what lets `dnf install` succeed with no
internet.

```hcl
resource "aws_vpc_endpoint" "interface" {
  for_each = toset(var.interface_endpoints)

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.app[*].id
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true
}
```
`for_each` makes one endpoint per name in the list; `each.key` is `"secretsmanager"`, `"ssm"`,
and so on. Each endpoint gets a network card in every app subnet. `private_dns_enabled` makes the
normal AWS hostname point at that card.

Why these four?
- `secretsmanager`: the website reads its password from here.
- `ssm`, `ssmmessages`, `ec2messages`: the trio Session Manager needs so you can log in and
  port-forward.

### 01-network/outputs.tf

Prints the VPC and subnet IDs. Nothing downstream *reads* these outputs; they are for you.

### Quiz 6

1. What route does the internal route table contain, and who added it?
2. Which endpoint makes `dnf install` work? Why does it cost nothing?
3. What does `for_each = toset([...])` do differently from `count`?

---

## 10. Line-by-Line: Stack 2, Database

### 02-database/data.tf

```hcl
data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-vpc"]
  }
}
```
"Find the VPC whose Name tag is `demo-vpc`." If Stack 1 has not been applied, this fails with a
clear error, which is exactly what you want.

```hcl
data "aws_subnets" "db" {
  filter { name = "vpc-id",  values = [data.aws_vpc.this.id] }
  filter { name = "tag:Tier", values = ["db"] }
}
```
"Find every subnet in that VPC tagged `Tier = db`." Returns a list of IDs.

### 02-database/main.tf

Passes the looked-up VPC ID, its CIDR block, and the db subnet IDs into the rds brick along with
the database settings from tfvars.

### modules/rds/main.tf

```hcl
resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.name}/db-credentials"
  recovery_window_in_days = 0
}
```
Create the safe named `demo/db-credentials`. Normally a deleted secret waits 7 to 30 days in case
you change your mind; `0` deletes instantly so `destroy` and re-`apply` work cleanly.

```hcl
resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username    # rcadmin
    password = var.db_password    # changeme
    dbname   = var.db_name
    port     = var.db_port
  })
}
```
Put the contents in the safe as JSON. The website will read `username` and `password`.
(`sensitive = true` on the variable keeps the password out of Terraform's screen output.)

```hcl
resource "aws_security_group" "app" {
  name   = "${var.name}-app-sg"
  ingress {
    from_port   = var.app_port   # 80
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
}
```
This is the bouncer the **app servers** will wear, but it is created here in the database stack.
Why? Because the database bouncer needs to point at it, and Stack 2 comes before Stack 3. It
allows port 80 from anywhere inside the VPC (that is what the port-forward tunnel arrives as).

```hcl
resource "aws_security_group" "db" {
  ingress {
    from_port       = var.db_port     # 5432
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
}
```
The database bouncer: PostgreSQL port 5432, **only** from things wearing the app security group.
Not from the VPC CIDR, not from the internet.

```hcl
resource "aws_db_subnet_group" "this" {
  subnet_ids = var.db_subnet_ids
}
```
RDS refuses to start without a subnet group covering two AZs. That is the reason we have two db
subnets.

```hcl
resource "aws_db_instance" "this" {
  identifier        = "${var.name}-db"     # demo-db
  engine            = "postgres"
  engine_version    = var.engine_version   # 17
  instance_class    = var.instance_class   # db.t3.micro
  allocated_storage = var.allocated_storage
  db_name           = var.db_name          # appdb
  username          = var.db_username      # rcadmin
  password          = var.db_password      # changeme
  port              = var.db_port          # 5432
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}
```
The database. `engine_version = "17"` means "newest 17.x". `publicly_accessible = false` means
no public hostname (there is no gateway anyway). `skip_final_snapshot = true` is for practice;
set it to `false` for real data.

**Stack 3 will look this up by its identifier `demo-db`.**

### Quiz 7

1. Why is the app security group created in the database stack instead of the compute stack?
2. Who is allowed to connect to port 5432?
3. What does `recovery_window_in_days = 0` change?

---

## 11. Line-by-Line: Stack 3, Compute

### 03-compute/data.tf

```hcl
data "aws_security_group" "app" {
  vpc_id = data.aws_vpc.this.id
  name   = "${var.project_name}-app-sg"
}
data "aws_db_instance" "this" {
  db_instance_identifier = "${var.project_name}-db"
}
data "aws_secretsmanager_secret" "db" {
  name = "${var.project_name}/db-credentials"
}
```
Three lookups of things Stack 2 built: the app bouncer (by name), the database (by identifier,
which gives us its address and port), and the safe (by name, which gives us its ARN).

### 03-compute/main.tf

```hcl
module "launch_template" {
  source            = "../modules/launch_template"
  security_group_id = data.aws_security_group.app.id
  secret_arn        = data.aws_secretsmanager_secret.db.arn
  db_endpoint       = data.aws_db_instance.this.address
  db_port           = data.aws_db_instance.this.port
  db_name           = data.aws_db_instance.this.db_name
  user_data         = var.user_data
  user_data_file    = var.user_data_file
}
```
Hand the recipe everything the website needs.

```hcl
module "asg" {
  source             = "../modules/asg"
  subnet_ids         = data.aws_subnets.app.ids
  launch_template_id = module.launch_template.launch_template_id
}
module "ec2" {
  source             = "../modules/ec2"
  subnet_id          = data.aws_subnets.app.ids[0]
  launch_template_id = module.launch_template.launch_template_id
}
```
Both the ASG and the single EC2 are stamped from the **same** recipe. Change the recipe once,
both get it (on their next replacement).

### modules/launch_template/main.tf

```hcl
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
```
Look up the newest Amazon Linux 2023 image. No hard-coded AMI IDs that go stale.

```hcl
resource "aws_iam_role" "instance" {
  assume_role_policy = jsonencode({
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}
```
The badge, and who may wear it (EC2 servers).

```hcl
resource "aws_iam_role_policy" "read_db_secret" {
  role   = aws_iam_role.instance.id
  policy = jsonencode({
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = var.secret_arn
    }]
  })
}
```
Permission 1: open exactly one safe. Least privilege.

```hcl
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
```
Permission 2: an AWS-managed policy that lets Session Manager talk to the server. Without it, the
`ssm` endpoints exist but the server never checks in.

```hcl
resource "aws_iam_instance_profile" "instance" {
  role = aws_iam_role.instance.name
}
```
The lanyard that clips the badge onto a server.

```hcl
locals {
  user_data_vars = { secret_arn = ..., db_endpoint = ..., db_port = ..., db_name = ..., region = ..., app_port = ... }

  user_data = (
    var.user_data != "" ? var.user_data :
    var.user_data_file != "" ? templatefile(var.user_data_file, local.user_data_vars) :
    templatefile("${path.module}/user_data.sh.tpl", local.user_data_vars)
  )
}
```
Pick the first-boot script. Priority: inline text from tfvars → your own file → the built-in
one. `templatefile` reads a file and fills in `${...}` placeholders.

```hcl
resource "aws_launch_template" "this" {
  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile { name = aws_iam_instance_profile.instance.name }
  user_data = base64encode(local.user_data)
}
```
The recipe: image, size, bouncer (from Stack 2), badge, first-boot script.

### modules/asg/main.tf

```hcl
resource "aws_autoscaling_group" "this" {
  min_size            = var.min_size          # 1
  max_size            = var.max_size          # 2
  desired_capacity    = var.desired_capacity  # 1
  vpc_zone_identifier = var.subnet_ids
  health_check_type   = "EC2"
  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }
}
```
The manager: keep between 1 and 2 servers, aim for 1, spread across both app subnets, replace any
that stop running. `EC2` health check = "is it powered on and passing AWS status checks" (there is
no load balancer to ask).

### modules/ec2/main.tf

```hcl
resource "aws_instance" "this" {
  subnet_id = var.subnet_id
  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }
}
```
One server, from the recipe, on the first app street. Everything else comes from the template.

### Overriding the first-boot script (03-compute/terraform.tfvars)

```hcl
# Option A: your own file; placeholders like ${db_endpoint} are filled in
user_data_file = "custom_user_data.sh.tpl"

# Option B: inline; sent exactly as written
user_data = <<-EOT
  #!/bin/bash
  echo hello > /tmp/hello.txt
EOT
```
User data runs only on **first** boot. After changing it:
`terraform apply -replace=module.ec2.aws_instance.this` (the ASG picks it up as it replaces servers).

### Quiz 8

1. Name the two permissions on the IAM role and what each is for.
2. Both the ASG and the EC2 use `version = "$Latest"`. What happens to a *running* server when you change the template?
3. If tfvars sets both `user_data` and `user_data_file`, which wins?

---

## 12. Line-by-Line: The Website Script

File: `modules/launch_template/user_data.sh.tpl`. Remember the constraint: **no internet**, so no
`pip install`. Everything comes from Amazon's package repo (via the S3 side-door) or Python's
standard library.

```bash
dnf install -y python3 python3-psycopg2
```
Python and the PostgreSQL driver, both from the Amazon Linux repo.

```bash
cat > /opt/app/app.env <<'ENV'
SECRET_ARN=${secret_arn}
DB_HOST=${db_endpoint}
...
ENV
```
Settings file. Terraform filled in the placeholders. No password here, only the safe's address.

```python
raw = subprocess.check_output([
    "aws", "secretsmanager", "get-secret-value",
    "--secret-id", os.environ["SECRET_ARN"], "--region", os.environ["AWS_REGION"],
    "--query", "SecretString", "--output", "text",
])
secret = json.loads(raw)
```
Use the AWS CLI (already on Amazon Linux) to open the safe. The call travels through the
Secrets Manager side-door and is allowed because of the IAM badge. Result: `{"username":
"rcadmin", "password": "changeme", ...}`.

```python
def db():
    return psycopg2.connect(host=..., port=..., dbname=..., user=secret["username"], password=secret["password"])
```
A helper that opens a fresh database connection.

```python
cur.execute("CREATE TABLE IF NOT EXISTS notes (id SERIAL PRIMARY KEY, text TEXT NOT NULL)")
```
Make the `notes` table once. `SERIAL` is PostgreSQL's auto-numbering.

```python
def list_notes():   cur.execute("SELECT id, text FROM notes ORDER BY id")            # READ
def add_note(t):    cur.execute("INSERT INTO notes (text) VALUES (%s)", (t,))         # CREATE
def update_note():  cur.execute("UPDATE notes SET text=%s WHERE id=%s", (t, nid))     # UPDATE
def delete_note():  cur.execute("DELETE FROM notes WHERE id=%s", (nid,))              # DELETE
```
The four CRUD functions. `%s` placeholders let the driver escape user input so nobody can sneak
SQL commands into a note (SQL injection).

```python
def page():
    ...
    t = html.escape(text)
```
Builds the HTML list. `html.escape` stops a note like `<script>` from running in the browser.

```python
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):   ...send page()...
    def do_POST(self):
        form = parse_qs(self.rfile.read(length).decode())
        parts = self.path.strip("/").split("/")
        if parts[0] == "add": add_note(text)
        elif parts[0] == "update": update_note(int(parts[1]), text)
        elif parts[0] == "delete": delete_note(int(parts[1]))
        self.send_response(303); self.send_header("Location", "/")
```
A web server from the standard library. GET shows the page; POST looks at the URL (`/add`,
`/update/3`, `/delete/3`) to decide which CRUD function to call, then redirects back to `/`.

```ini
[Service]
EnvironmentFile=/opt/app/app.env
ExecStart=/usr/bin/python3 /opt/app/app.py
Restart=always
```
A systemd service so the app starts at boot and restarts if it crashes.

### Quiz 9

1. Why does the script use the AWS CLI instead of `pip install boto3`?
2. What does `html.escape` protect against? What does `%s` protect against?
3. Which HTTP status does the app send after a POST, and why?

---

## 13. Optional Stack 4: Restore a Database from a Snapshot

A **snapshot** is a frozen photo of your database at one moment. Restoring from it gives you a
brand-new database with all the same tables and rows. This is how you clone a database for
testing, recover from a mistake, or move to a bigger server.

The `rds_from_snapshot` module does three things:

1. Finds the snapshot (an exact name you give, or the newest one for a source database).
2. Restores it as a new RDS instance and **resets the master password** to a fresh random one.
3. Stores that new password (plus host, port, username) in a new Secrets Manager secret.

### Step 1: Make a snapshot of demo-db

RDS makes automated snapshots daily, but for the tutorial make one now:

```bash
aws rds create-db-snapshot --db-instance-identifier demo-db --db-snapshot-identifier demo-db-snap-1
aws rds wait db-snapshot-available --db-snapshot-identifier demo-db-snap-1   # 2 to 5 minutes
```

Tip: add a few notes in the website first so you can prove they come back.

### Step 2: Apply Stack 4

```bash
cd 04-database-restore
terraform init          # downloads the aws AND random providers
terraform plan          # shows snapshot_used = demo-db-snap-1
terraform apply         # 8 to 12 minutes
```

### Step 3: Read the new password and check the data

```bash
aws secretsmanager get-secret-value --secret-id demo/demo-db-restored-credentials \
  --query SecretString --output text
# {"username":"rcadmin","password":"<20 random chars>","host":"demo-db-restored....","port":5432,...}
```

Log in to the app server with Session Manager (section 4) and:

```bash
sudo dnf install -y postgresql17
S=$(aws secretsmanager get-secret-value --secret-id demo/demo-db-restored-credentials --region us-east-1 --query SecretString --output text)
export PGPASSWORD=$(echo "$S" | python3 -c 'import sys,json;print(json.load(sys.stdin)["password"])')
psql -h $(echo "$S" | python3 -c 'import sys,json;print(json.load(sys.stdin)["host"])') -U rcadmin -d appdb -c 'SELECT * FROM notes;'
```

Your notes are there, and the **old** password `changeme` no longer works on the restored copy.

### Step 4: Destroy when done

```bash
terraform destroy          # in 04-database-restore
aws rds delete-db-snapshot --db-snapshot-identifier demo-db-snap-1   # snapshots cost storage
```

### Line-by-line: modules/rds_from_snapshot/main.tf

```hcl
data "aws_db_snapshot" "latest" {
  count                  = var.snapshot_identifier == "" ? 1 : 0
  db_instance_identifier = var.source_db_identifier
  most_recent            = true
}
```
A data lookup with `count = 1` or `0`: it only runs if you did **not** name an exact snapshot.
`most_recent = true` picks the newest snapshot of the source database.

```hcl
locals {
  snapshot_id = var.snapshot_identifier != "" ? var.snapshot_identifier : data.aws_db_snapshot.latest[0].id
  secret_name = var.secret_name != "" ? var.secret_name : "${var.name}/${var.identifier}-credentials"
}
```
Decide which snapshot and which secret name to use. `[0]` reaches into the counted data source.

```hcl
resource "random_password" "db" {
  length           = var.password_length
  special          = true
  override_special = "!#$%^&*()-_=+"
}
```
The `random` provider invents a password. `override_special` limits punctuation to characters RDS
accepts (it rejects `/`, `@`, `"` and spaces). The value is saved in state so it does not change
on every apply.

```hcl
resource "aws_db_instance" "restored" {
  identifier          = var.identifier
  snapshot_identifier = local.snapshot_id
  instance_class      = var.instance_class
  password            = random_password.db.result
  ...
}
```
`snapshot_identifier` is the magic line: instead of creating an empty database, RDS restores this
snapshot. Engine, version, `db_name`, storage size and the master **username** are locked to
whatever the snapshot had; you cannot set them here. The **password** is the one thing you may
reset, which is why we can hand it the new random one.

```hcl
resource "aws_secretsmanager_secret_version" "db" {
  secret_string = jsonencode({
    username = aws_db_instance.restored.username   # read back from the snapshot
    password = random_password.db.result
    host     = aws_db_instance.restored.address
    port     = aws_db_instance.restored.port
    dbname   = aws_db_instance.restored.db_name
    engine   = aws_db_instance.restored.engine
  })
}
```
Write everything an app needs into the new secret. The username is read *from the restored
instance* because we never typed it; it came with the snapshot.

### 04-database-restore/data.tf

Looks up the VPC, the `Tier = db` subnets, and Stack 2's `demo-db-sg`. Reusing the DB security
group means the same app servers are allowed to connect to the copy.

### Quiz 10

1. Name three things about a restored database that you cannot change because they come from the snapshot.
2. What is the one credential you *can* change on restore?
3. Which setting makes Terraform pick the newest snapshot automatically?
4. Which extra provider does this module need, and how do you get it?

---

## 14. Backup AWS CLI Commands

Terraform is the normal way to view and destroy. If a state file is lost, these still work
because they search by the `Project` tag or by name.

### View

```bash
./scripts/aws-view.sh demo us-east-1
```

Handy one-liners:

```bash
aws ec2 describe-vpc-endpoints --filters Name=tag:Project,Values=demo --output table
aws secretsmanager get-secret-value --secret-id demo/db-credentials --query SecretString --output text
aws rds describe-db-instances --db-instance-identifier demo-db --query 'DBInstances[0].[EngineVersion,DBInstanceStatus,Endpoint.Address]'
aws ssm describe-instance-information --output table        # which servers can you log in to?
aws autoscaling describe-auto-scaling-groups --output table
```

### Destroy (emergency only)

```bash
./scripts/aws-destroy.sh demo us-east-1
```

Deletes in reverse stack order: ASG → instances → launch template → IAM → RDS → subnet group →
secret → VPC endpoints → security groups → subnets → route table → VPC. It waits for endpoint
network cards to release before deleting security groups, which is the usual sticking point.

Snapshot commands:

```bash
aws rds describe-db-snapshots --db-instance-identifier demo-db --query 'DBSnapshots[].[DBSnapshotIdentifier,Status,SnapshotCreateTime]' --output table
aws rds delete-db-snapshot --db-snapshot-identifier demo-db-snap-1
aws rds delete-db-instance --db-instance-identifier demo-db-restored --skip-final-snapshot
aws secretsmanager delete-secret --secret-id demo/demo-db-restored-credentials --force-delete-without-recovery
```

**Prefer `terraform destroy` in 04 (if used), 03, then 02, then 01.**

### Quiz 11

1. Why must VPC endpoints be deleted before the security groups?

---

## 15. Best Practices, Pros and Cons

| Choice | Pro | Con | When to change |
|---|---|---|---|
| **No internet gateway** | Nothing can reach the servers from outside; nothing leaks out | Needs endpoints ($) and Session Manager to use it | Add an IGW + ALB in public subnets if the site must be public |
| **VPC endpoints** | Private path to AWS APIs and packages | ~$14.60/month per interface endpoint across two AZs (see `COSTS.md`) | Drop the `ssm*` three if you never need a shell |
| **Three stacks** | Small blast radius, clear ownership | More commands, ordering matters | Merge if one person owns everything and it is small |
| **Tag/name lookups** between stacks | No shared state; each stack is self-contained | Renaming breaks lookups | `terraform_remote_state` with an S3 backend is the alternative |
| **Password in Secrets Manager** | One source of truth; app reads it with a badge | The password is also in tfvars/state | Use `manage_master_user_password = true` and let RDS generate it |
| `rcadmin` / `changeme` | Easy to follow the tutorial | Terrible password | Change it before real data |
| **Standard-library web server** | Zero internet needed | Not built for real traffic | Real apps: gunicorn/nginx, a container, or ECS |
| **App SG lives in the DB stack** | DB SG can reference it, no cycle | Slightly surprising location | Or make a tiny "shared security groups" stack between 1 and 2 |
| `skip_final_snapshot = true` | Clean destroy | Data gone | `false` + `final_snapshot_identifier` for real data |
| Local state files | Zero setup | Easy to lose | S3 backend with locking |

General habits used here: modules, defaults in `variables.tf` with overrides in `terraform.tfvars`,
version pins, `default_tags`, no hard-coded IDs, `terraform fmt` + `validate`, always `plan`
before `apply`.

---

## 16. Quiz Answer Key

**Quiz 1:** 1) Apply 01 → 02 → 03; destroy 03 → 02 → 01. 2) `data` blocks look up the VPC by its `Name` tag and subnets by their `Tier` tag.

**Quiz 2:** 1) Stack 2; RDS takes 8 to 12 minutes to provision. 2) Runs the `data` lookups to find the VPC and db subnets from Stack 1.

**Quiz 3:** 1) The VPC has no internet gateway and the server has no public IP, so there is no path from your laptop. 2) AWS Systems Manager Session Manager (via the ssm endpoints and the IAM policy).

**Quiz 4:** 1) `resource` creates; `data` looks up something that already exists. 2) `module.vpc.vpc_id`.

**Quiz 5:** 1) Gateway = a route-table entry, free, only S3 and DynamoDB. Interface = a network card in your subnet, hourly cost, most other services. 2) An internet gateway and a `0.0.0.0/0` route (and public IPs).

**Quiz 6:** 1) Only `local` (the VPC CIDR); AWS adds it automatically. 2) The S3 gateway endpoint; gateway endpoints have no hourly charge. 3) `for_each` makes one instance per unique value with names like `interface["ssm"]`; `count` makes numbered copies `[0]`, `[1]`.

**Quiz 7:** 1) The DB security group must reference the app SG, and Stack 2 is applied before Stack 3. 2) Only resources wearing the app security group. 3) The secret is deleted immediately instead of waiting 7 to 30 days.

**Quiz 8:** 1) An inline policy allowing `secretsmanager:GetSecretValue` on one secret (read the password) and `AmazonSSMManagedInstanceCore` (Session Manager access). 2) Nothing; it keeps running the old version until it is replaced. 3) `user_data` (inline).

**Quiz 9:** 1) There is no internet, so PyPI is unreachable; the CLI ships with Amazon Linux. 2) `html.escape` prevents cross-site scripting in the browser; `%s` placeholders prevent SQL injection in the database. 3) 303 See Other, which tells the browser to GET `/` again so the refreshed list is shown.

**Quiz 10:** 1) The username, engine, version, db_name and storage size; they are baked into the snapshot. 2) The password; the module sets it to a new random one. 3) `most_recent = true` on the `aws_db_snapshot` data source. 4) `random_password` and the `hashicorp/random` provider; run `terraform init` so it downloads.

**Quiz 11:** 1) Interface endpoints hold network cards that use the endpoint security group; AWS will not delete a security group that a network card still references.
