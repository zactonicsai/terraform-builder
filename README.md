# Terraform Launch Template + EC2 modules

```
modules/
  launch_template/   # aws_launch_template with user data, EBS, IMDSv2, IAM profile, tags
  ec2/               # aws_instance(s) launched from a template, with optional overrides + EIP
examples/
  simple-website/    # Nginx "hello" page + JS, configured entirely via user data
```

## Run the example

```bash
cd examples/simple-website
terraform init
terraform apply
open "$(terraform output -raw website_url)"   # give cloud-init ~1 minute
```

## Notes
- Pass `user_data` as **plain text**; the launch template module base64-encodes it.
- Set `associate_public_ip_address` on the template to switch it to a `network_interfaces` block
  (security groups move into that block automatically, as AWS requires).
- Any EC2 module variable left `null` inherits the value from the launch template.
- `launch_template_version` accepts a number, `"$Latest"`, or `"$Default"`.

## AWS CLI helper scripts (`scripts/`)

All scripts locate resources by the `Project` tag (default `hello-web`) and `REGION` (default `us-east-1`):

```bash
PROJECT=hello-web REGION=us-east-1 scripts/view-resources.sh   # list everything
scripts/destroy/01-instances.sh                                 # step-by-step teardown
scripts/destroy/02-eips.sh
scripts/destroy/03-launch-template.sh
scripts/destroy/04-security-group.sh
scripts/destroy-all.sh                                          # everything, in order
FORCE=1 scripts/destroy-all.sh                                  # no prompts
```

> Prefer `terraform destroy` when the state file is intact. The CLI scripts are for
> inspection, or for cleaning up when Terraform state is lost.
# terraform-builder
