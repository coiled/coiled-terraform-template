# Coiled Workspace Terraform Template

This terraform module is intended to serve as a template for users who required a high degree of customization for their Coiled workspace.

We recommend you copy this template and modify it to fit your needs. Modifications are possible but we recommend contacting <support@coiled.io> for detailed help on the process.

This template creates a highly restricted version of the standard Coiled policies and roles, while still allowing users to proceed through setup in a normal fashion. Coiled will be able to "adopt" resources without being able to modify them.

## VPC Requirements

- The VPC must allow outbound traffic to the Coiled control plane for all instances.
- Instances must be able to communicate with each other on all ports.
- For the easiest setup, users should be able to connect from their client environment to the scheduler on ports 8787-8786, although if this is an issue for your security requirements alternatives are possible.

## Other limitations

- The name of the Cloudwatch log group cannot be altered and must match the Coiled workspace name
- The name of the policy attached to the "coiled cluster role" must be `CoiledInstancePolicy`
- The name of the coiled cluster role must take the form `coiled-<workspace-name>`
- The name of the instance profile must take the form `coiled-<workspace-name>`

## Finishing setup when the template is applied

The template outputs contain all the information needed to finish coiled setup

Using this example:

```shell
coiled_cluster_sg = "sg-0797fe44409cb07b0"
coiled_external_id = "8b7846c6cd4b645d"
coiled_instance_profile_arn = "arn:aws:iam::687241535879:instance-profile/coiled-aaaaaa"
coiled_role_arn = "arn:aws:iam::687241535879:role/coiled-control-plane-role"
coiled_scheduler_sg = "sg-00c0fa7479dfcb482"
coiled_subnet_ids = [
  "subnet-0905c86d89e0c38a4",
  "subnet-07460177bd0443f90",
  "subnet-07abb1162257c2c37",
]
coiled_vpc_id = "vpc-03dc146b0f3568563"
```

We take `coiled_role_arn` and `coiled_external_id` and fill out the cloud provider setup form.

https://github.com/coiled/coiled-terraform-template/assets/546891/bd234487-befc-42c2-b6ab-e59b78fc8816

Next we can move to the `Infrastruture` tab and have Coiled adopt the instance profile.

https://github.com/coiled/coiled-terraform-template/assets/546891/34d102ff-a99e-4acc-b903-2d707b79d686

Now we can adopt the VPC, and subnets we created.

https://github.com/coiled/coiled-terraform-template/assets/546891/92c33217-c241-43bc-93c7-e6eaf14cb8f7

Your Coiled workspace is now ready to create clusters!
