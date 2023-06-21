# Deploy Amazon EKS Cluster

GitHub action to deploy an EKS cluster, defining VPC's, Secruity Groups, EC2 Instance templates and everything needed, taking minimum imputs from the user.
Will generate a cluster of EC2 Instances running Amazon EKS Image, with version 1.27 as default.

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
      uses: bitovi/github-actions-deploy-eks@v0.1.0
      with:
        aws_access_key_id: ${{ secrets.AWS_ACCESS_KEY_ID_SANDBOX}}
        aws_secret_access_key: ${{ secrets.AWS_SECRET_ACCESS_KEY_SANDBOX}}
        aws_default_region: us-east-1
  
        aws_eks_create: true
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
      uses: bitovi/github-actions-deploy-eks@v0.1.0
      with:
        aws_access_key_id: ${{ secrets.AWS_ACCESS_KEY_ID_SANDBOX}}
        aws_secret_access_key: ${{ secrets.AWS_SECRET_ACCESS_KEY_SANDBOX}}
        aws_default_region: us-east-1
        tf_state_bucket_destroy: true 
  
        aws_eks_create: true
        aws_eks_environment: qa
        aws_eks_stackname: qa-stack
        aws_eks_cluster_version: 1.25
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

The following inputs can be used as `step.with` keys
<br/>
<br/>



user_data_file ?  está al pepe
instance_image ?

#### **Action defaults Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `checkout` | Boolean | Set to `false` if the code is already checked out. (Default is `true`). |
| `bitops_code_only` | Boolean  | Set to `true` to destroy the stack - Will delete the `elb logs bucket` after the destroy action runs. |
| `bitops_code_store` | Boolean | AWS access key ID |
| `tf_state_bucket` | String | AWS S3 bucket name to use for Terraform state. See [note](#s3-buckets-naming) | 
| `tf_state_bucket_destroy` | Boolean | Force purge and deletion of S3 bucket defined. Any file contained there will be destroyed. `stack_destroy` must also be `true`. Default is `false`. |
<hr/>
<br/>

#### **Action defaults Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_access_key_id` | String | AWS access key ID |
| `aws_secret_access_key` | String | AWS secret access key |
| `aws_session_token` | String | AWS session token |
| `aws_default_region` | String | AWS default region. Defaults to `us-east-1` |
<hr/>
<br/>

#### **Action defaults Inputs**
| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `aws_eks_create` | String | Define if an EKS cluster should be created |
| `aws_eks_region` | String | Define the region where EKS cluster should be created |
| `aws_eks_security_group_name_master` | String | Define the security group name master |
| `aws_eks_security_group_name_worker` | String | Define the security group name worker |
| `aws_eks_environment` | String | Specify the eks environment name. ex: `dev` or `test` |
| `aws_eks_stackname` | String | Specify the eks stack name for your environment. (ex: `eks-test`) |
| `aws_eks_cidr_block` | String | Define Base CIDR block which is divided into subnet CIDR blocks (ex: `10.0.0.0/16`) |
| `aws_eks_workstation_cidr` | String | Enter your remote public CIDR or IP to add it to Worker nodes security groups |
| `aws_eks_availability_zones` | String | Comma separated list of availability zones |
| `aws_eks_private_subnets` | String | Comma separated list of private subnets. |
| `aws_eks_public_subnets` | String | Comma separated list of public subnets. |
| `aws_eks_cluster_name` | String | Specify the k8s cluster name |
| `aws_eks_cluster_log_types` | String | Specify the k8s cluster log type |
| `aws_eks_cluster_version` | String | Specify the k8s cluster version. Defaults to `1.27` |
| `aws_eks_instance_type` | String | Define the EC2 instance type. See [this list](https://aws.amazon.com/ec2/instance-types/) for reference. |
| `aws_eks_instance_ami_id` | String | AWS AMI ID. Will default to the latest Amazon EKS Node image for the cluster version. |
| `aws_eks_instance_user_data_file` | String | Relative path in the repo for a user provided script to be executed with the EC2 Instance creation. |
| `aws_eks_ec2_key_pair` | String | Enter the existing ec2 key pair for worker nodes. If none, will create one. |
| `aws_eks_store_keypair_sm` | String | If true, will store the newly created keys in Secret Manager |
| `aws_eks_desired_capacity` | String | Enter the desired capacity for the worker nodes |
| `aws_eks_max_size` | String | Enter the max_size for the worker nodes |
| `aws_eks_min_size` | String | Enter the min_size for the worker nodes |
| `input_helm_charts` | String | Relative path to the folder from project containing Helm charts to be installed. Could be uncompressed or compressed (.tgz) files. |
<hr/>
<br/>

## Note about resource identifiers

Most resources will contain the tag `${GITHUB_ORG_NAME}-${GITHUB_REPO_NAME}-${GITHUB_BRANCH_NAME}`, some of them, even the resource name after. 
We limit this to a 60 characters string because some AWS resources have a length limit and short it if needed.

We use the kubernetes style for this. For example, kubernetes -> k(# of characters)s -> k8s. And so you might see some compressions are made.

For some specific resources, we have a 32 characters limit. If the identifier length exceeds this number after compression, we remove the middle part and replace it for a hash made up from the string itself. 

### S3 buckets naming

Buckets names can be made of up to 63 characters. If the length allows us to add -tf-state, we will do so. If not, a simple -tf will be added.

## Made with BitOps
[BitOps](https://bitops.sh) allows you to define Infrastructure-as-Code for multiple tools in a central place.  This action uses a BitOps [Operations Repository](https://bitops.sh/operations-repo-structure/) to set up the necessary Terraform and Ansible to create infrastructure and deploy to it.

## Contributing
We would love for you to contribute to [bitovi/github-actions-deploy-docker-to-ec2](https://github.com/bitovi/github-actions-deploy-docker-to-ec2).
Would you like to see additional features?  [Create an issue](https://github.com/bitovi/github-actions-deploy-docker-to-ec2/issues/new) or a [Pull Requests](https://github.com/bitovi/github-actions-deploy-docker-to-ec2/pulls). We love discussing solutions!

## License
The scripts and documentation in this project are released under the [MIT License](https://github.com/bitovi/github-actions-deploy-docker-to-ec2/blob/main/LICENSE).
