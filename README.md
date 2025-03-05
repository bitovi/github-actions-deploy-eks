# Deploy Amazon EKS Cluster

GitHub action to deploy an EKS cluster, defining VPC's, Security Groups, EC2 Instance templates and everything needed, taking minimum imputs from the user.
Will generate a cluster of EC2 Instances running Amazon EKS Image, with version 1.28 as default.

## Requirements

1. An AWS account

You'll need [Access Keys](https://docs.aws.amazon.com/powershell/latest/userguide/pstools-appendix-sign-up.html) from an [AWS account](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/)

## Example usage

Create `.github/workflow/deploy.yaml` with the following to build on push.

### Example usage
```yaml
name: Basic deploy
on:
  push:
    branches: [ main ]

jobs:
  Deploy-Cluster:
    runs-on: ubuntu-latest

    steps:
    - name: Create EKS Cluster
      uses: bitovi/github-actions-deploy-eks@v0.1.2
      with:
        aws_access_key_id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws_secret_access_key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws_eks_cluster_admin_role_arn: arn:aws:iam::123456789012:role/AWSReservedSSO_AdministratorAccess_1234567890123456
        aws_additional_tags: {"key1": "value1", "key2": "value2"}
```

### Advanced example
```yaml
name: Advanced deploy
on:
  push:
    branches: [ main ]

jobs:
  Deploy-Cluster:
    runs-on: ubuntu-latest

    steps:
    - name: Create EKS Cluster
      uses: bitovi/github-actions-deploy-eks@v0.1.2
      with:
        aws_access_key_id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws_secret_access_key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws_default_region: us-east-1
        aws_eks_cluster_admin_role_arn: arn:aws:iam::123456789012:role/AWSReservedSSO_AdministratorAccess_1234567890123456
        
        # tf_stack_destroy: true
        tf_state_bucket_destroy: true 
  
        aws_eks_environment: qa
        aws_eks_stackname: qa-stack
        aws_eks_cluster_version: 1.29
        aws_eks_instance_type: t2.small

        aws_eks_max_size: 5
        aws_eks_min_size: 2
        aws_eks_desired_capacity: 3

        aws_eks_cidr_block: 10.0.0.0/16
        aws_eks_availability_zones: "us-east-1a,us-east-1f,us-east-1c"
        aws_eks_private_subnets: "10.0.1.0/24,10.0.2.0/24,10.0.3.0/24"
        aws_eks_public_subnets: "10.0.11.0/24,10.0.12.0/24,10.0.13.0/24"
```

## Customizing

### Inputs
1. [Action Defaults](#action-defaults-inputs)
1. [AWS](#aws-inputs)
1. [EKS](#eks-inputs)
1. [Extras](#eks-extras) ⚠️
1. [VPC](#vpc-inputs)

> ⚠️ Using any kind of **extras** can lead to the creation of load balancers. If doing so, manual intervention to delete them after will be needed. (You'll need to delete a load balancer and the VPC manually, then run the job )


### Outputs
1. [Action Outputs](#action-outputs)

The following inputs can be used as `step.with` keys
<br/>
<br/>
#### **Action defaults Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `checkout` | Boolean | Set to `false` if the code is already checked out. (Default is `true`). |
| `bitops_code_only` | Boolean  | Set to `true` to run a code generation test. |
| `bitops_code_store` | Boolean | Store the generated code in an artifact to download. |
| `tf_stack_destroy` | Boolean  | Set to `true` to destroy the stack - Will delete the `elb logs bucket` after the destroy action runs. |
| `tf_state_file_name` | String | Change this to be anything you want to. Carefull to be consistent here. A missing file could trigger recreation, or stepping over destruction of non-defined objects. Defaults to `tf-state-aws`. |
| `tf_state_file_name_append` | String | Appends a string to the tf-state-file. Setting this to `unique` will generate `tf-state-aws-unique`. (Can co-exist with `tf_state_file_name`) |
| `tf_state_bucket` | String | AWS S3 bucket name to use for Terraform state. See [note](#s3-buckets-naming) | 
| `tf_state_bucket_destroy` | Boolean | Force purge and deletion of S3 bucket defined. Any file contained there will be destroyed. `tf_stack_destroy` must also be `true`. Default is `false`. |
<hr/>
<br/>

#### **AWS Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_access_key_id` | String | AWS access key ID |
| `aws_secret_access_key` | String | AWS secret access key |
| `aws_session_token` | String | AWS session token |
| `aws_default_region` | String | AWS default region. Defaults to `us-east-1` |
| `aws_resource_identifier` | String | Set to override the AWS resource identifier for the deployment. Defaults to `${GITHUB_ORG_NAME}-${GITHUB_REPO_NAME}-${GITHUB_BRANCH_NAME}`. |
| `aws_additional_tags` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to all provisioned resources.|
<hr/>
<br/>

#### **EKS Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_eks_create` | Boolean | Define if an EKS cluster should be created. Defaults to `true`. |
| `aws_eks_security_group_name_cluster` | String | Define the security group name master. Defaults to `SG for ${var.aws_resource_identifier} - EKS Cluster`. |
| `aws_eks_security_group_name_node` | String | Define the security group name worker. Defaults to `SG for ${var.aws_resource_identifier} - EKS Node`. |
| `aws_eks_environment` | String | Specify the eks environment name. Defaults to `env` |
| `aws_eks_management_cidr` | String | Comma separated list of remote public CIDRs blocks to add it to Worker nodes security groups. |
| `aws_eks_allowed_ports` | String | Allow incoming traffic from this port. Accepts comma separated values, matching 1 to 1 with `aws_eks_allowed_ports_cidr`. |
| `aws_eks_allowed_ports_cidr` | String | Allow incoming traffic from this CIDR block. Accepts comma separated values, matching 1 to 1 with `aws_eks_allowed_ports`. If none defined, will allow all incoming traffic. |
| `aws_eks_cluster_name` | String | Specify the k8s cluster name. Defaults to `${var.aws_resource_identifier}-cluster` |
| `aws_eks_cluster_admin_role_arn` | String | Role ARN to grant cluster-admin permissions. | 
| `aws_eks_cluster_log_types` | String | Comma separated list of cluster log type. See [this AWS doc](https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html). Defaults to `api,audit,authenticator`. |
| `aws_eks_cluster_log_retention_days` | String | Days to store logs. Defaults to `7`. | 
| `aws_eks_cluster_logs_skip_destroy` | Boolean | Skip deletion of cluster logs if set to true. Defaults to `false`. |
| `aws_eks_cluster_version` | String | Specify the k8s cluster version. Defaults to `1.28` |
| `aws_eks_instance_type` | String | Define the EC2 instance type. See [this list](https://aws.amazon.com/ec2/instance-types/) for reference. Defaults to `t3a.medium`. |
| `aws_eks_instance_ami_id` | String | AWS AMI ID. Will default to the latest Amazon EKS Node image for the cluster version. |
| `aws_eks_instance_user_data_file` | String | Relative path in the repo for a user provided script to be executed with the EC2 Instance creation. See note. |
| `aws_eks_ec2_key_pair` | String | Enter an existing ec2 key pair name for worker nodes. If none, will create one. |
| `aws_eks_store_keypair_sm` | Boolean | If true, will store the newly created keys in Secret Manager. |
| `aws_eks_desired_capacity` | String | Enter the desired capacity for the worker nodes. Defaults to `2`. |
| `aws_eks_max_size` | String | Enter the max_size for the worker nodes. Defaults to `4`. |
| `aws_eks_min_size` | String | Enter the min_size for the worker nodes. Defaults to `2`. |
| `aws_eks_additional_tags` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to eks provisioned resources.|
<hr/>
<br/>

#### **EKS Extras**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `prometheus_enable` | Boolean | Set to `true`to enable deployment through chart. |
| `grafana_enable` | Boolean | Set to `true`to enable deployment through chart. |
| `loki_enable` | Boolean | Set to `true` to enable deployment through chart. |
| `nginx_enable` | Boolean | Set to `true` to enable deployment through chart. |
| `input_helm_charts` | String | Relative path to the folder from project containing Helm charts to be installed. Could be uncompressed or compressed (.tgz) files. |
<hr/>
<br/>

#### **VPC Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_vpc_create` | Boolean | Define if a VPC should be created. Defaults to `true`. |
| `aws_vpc_name` | String | Define a name for the VPC. Defaults to `VPC for ${aws_resource_identifier}`. |
| `aws_vpc_cidr_block` | String | Define Base CIDR block which is divided into subnet CIDR blocks. Defaults to `10.0.0.0/16`. |
| `aws_vpc_public_subnets` | String | Comma separated list of public subnets. Defaults to `10.0.101.0/24,10.0.102.0/24`. |
| `aws_vpc_private_subnets` | String | Comma separated list of private subnets. If no input, no private subnet will be created. Defaults to `10.0.1.0/24,10.0.2.0/24`. |
| `aws_vpc_availability_zones` | String | Comma separated list of availability zones. Defaults to `us-east-1a,us-east-1b` value. |
| `aws_vpc_id` | String | **Existing** AWS VPC ID to use. Accepts `vpc-###` values. |
| `aws_vpc_subnet_id` | String | **Existing** AWS VPC Subnet ID. If none provided, will pick one. (Ideal when there's only one). |
| `aws_vpc_enable_nat_gateway` | String | Adds a NAT gateway for each public subnet. Defaults to `true`. |
| `aws_vpc_single_nat_gateway` | String | Toggles only one NAT gateway for all of the public subnets. Defaults to `true`. |
| `aws_vpc_external_nat_ip_ids` | String | **Existing** comma separated list of IP IDs if reusing. (ElasticIPs). |
| `aws_vpc_additional_tags` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider), any tags put here will be added to vpc provisioned resources.|
<hr/>
<br/>

#### **Action Outputs**
| Name             | Description                        |
|------------------|------------------------------------|
| `aws_vpc_id` | The selected VPC ID used. |
| `ecs_load_balancer_dns` | ECS ALB DNS Record. |
| `ecs_dns_record` | ECS DNS URL. |
| `ecs_sg_id` | ECS SG ID. |
| `ecs_lb_sg_id` | ECS LB SG ID. |
<hr/>
<br/>


## Helm charts
We have **aws-auth**,**ingress**, **grafana**, **prometheus** and **loki** as helm charts which can be called by deployment repo to install in the aws eks cluster. User can pass inputs like `grafana_enable`, `loki_enable`, `nginx_enable` and/or `prometheus_enable` in the deployment repo along with aws access information, and these charts would be installed along with eks creation in aws.

## Note about resource identifiers

Most resources will contain the tag `${GITHUB_ORG_NAME}-${GITHUB_REPO_NAME}-${GITHUB_BRANCH_NAME}`, some of them, even the resource name after. 
We limit this to a 60 characters string because some AWS resources have a length limit and short it if needed.

We use the kubernetes style for this. For example, kubernetes -> k(# of characters)s -> k8s. And so you might see some compressions are made.

For some specific resources, we have a 32 characters limit. If the identifier length exceeds this number after compression, we remove the middle part and replace it for a hash made up from the string itself. 

## Note about tagging

There's the option to add any kind of defined tags to each grouping module. Will be added to the commons tagging.
See first example for the correct formatting.

### S3 buckets naming

Buckets names can be up to 63 characters. If the length allows, -tf-state will be suffixed to the name. Otherwise, only -tf will be added.
In all cases, the name hashing described above will be used to keep the lengths within limit.

## EC2 User data

You can provide any bash script you wish to run after instance creation. See [this note](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts).

As a default, if not setting any instance ami_id, we will take care of setting up the amazon-ssm-agent, point to the cluster endpoint, some nfs tools and update the instance name tag to be ${aws_eks_environment}-eksworker-node-${private-ip} once it's done.

## Made with BitOps
[BitOps](https://bitops.sh) allows you to define Infrastructure-as-Code for multiple tools in a central place.  This action uses a BitOps [Operations Repository](https://bitops.sh/operations-repo-structure/) to set up the necessary Terraform and Ansible to create infrastructure and deploy to it.

## Contributing
We would love for you to contribute to [bitovi/github-actions-deploy-docker-to-ec2](https://github.com/bitovi/github-actions-deploy-eks).
Would you like to see additional features?  [Create an issue](https://github.com/bitovi/github-actions-deploy-eks/issues/new) or a [Pull Requests](https://github.com/bitovi/github-actions-deploy-eks/pulls). We love discussing solutions!

## License
The scripts and documentation in this project are released under the [MIT License](https://github.com/bitovi/github-actions-deploy-eks/blob/main/LICENSE).

# Provided by Bitovi
[Bitovi](https://www.bitovi.com/) is a proud supporter of Open Source software.

# We want to hear from you.
Come chat with us about open source in our Bitovi community [Discord](https://discord.gg/zAHn4JBVcX)!
