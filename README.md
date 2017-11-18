# terraform-grafana
Terraform with Packer to provision a Grafana server behind an AWS Application load balancer.  

`make help` will get you started.
```
$ make help
apply                          DANGER! Runs changes against your environment
destroy                        DANGER! Destroys a set of resources
destroy-target                 Specifically choose a resource to destroy
graph                          Creates a graph of the resources that Terraform is aware of
plan-destroy                   Runs a plan to show what will be destroyed
plan                           Runs a plan to show proposed changes.
state-apply                    Apply changes for Remote State
state-destroy                  DANGER! Destroys Remote State
state-plan-destroy             Runs a plan to show what will be destroyed for Remote State
state-plan                     Runs a plan to see what will be applied for Remote State
state-update                   Gets any modules / updates for Remote State
update                         Gets a newer version of the state
```

`make state-apply` creates the bucket and lock table and only needs to be run once.

Builds AMIs for Grafana server with packer.  Looks for the latest Linux from Amazon and instruments it with CloudWatch logs.
Detects when new images are available.

## OS X

On mac there are issues with `make` being downlevel.  I had to `brew install make --with-default-names` to successfully run
`ENVIRONMENT=dev make plan`.  Turns out on OS X `make` is version 3.81 and the command `.ONESHELL:` requires >= 3.82.

## Outputs
```
Outputs:

amazon_id = ami-1234abcd
grafana_id = ami-abcd1234
private_ip = 172.64.32.16
private_subnet_ids = [
    subnet-9876zyxw,
    subnet-zyxw9876
]
public_ip = 13.14.15.16
public_subnet_ids = [
    subnet-2168df46,
    subnet-0508cc5e
]
sg_ssh_id = sg-5555mmmm
user = ec2-user
vpc_id = vpc-5m5m5m5m
```
