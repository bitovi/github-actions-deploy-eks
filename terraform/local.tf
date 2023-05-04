locals {
  #general config

  aws-profile   = "default"
  aws-region    = "us-east-1"
  environment   = "test"
  account_id    = "755521597925"
  stackname     = "eks-test"
  subsystem_val = "primary"
  #reponame = "bitovi/operations-recruiting"

  #vpc related config values
  vpc_name                = "${local.stackname}-${local.subsystem_val}-vpc"
  vpc_cidr                = "10.0.0.0/16"
  availability_zones      = ["us-east-1a","us-east-1b"]
  private_subnets         = ["10.0.1.0/24","10.0.2.0/24"]
  public_subnets          = ["10.0.101.0/24","10.0.102.0/24"]
  kubernetes_cluster_name = "${local.environment}-ekscluster"

  #Userdata for nodes
  node-userdata = <<USERDATA
  #!/bin/bash
  set -o xtrace
  # These are used to install SSM Agent to SSH into the EKS nodes.
  sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
  systemctl enable amazon-ssm-agent
  systemctl restart amazon-ssm-agent
  /etc/eks/bootstrap.sh --apiserver-endpoint '${module.eks_master.eks_master_endpoint}' --b64-cluster-ca '${module.eks_master.cluster_certificate_authority_data}' '${local.kubernetes_cluster_name}'
  # Retrieve the necessary packages for `mount` to work properly with NFSv4.1
  sudo yum update -y
  sudo yum install -y amazon-efs-utils nfs-utils nfs-utils-lib
  # after the eks bootstrap and necessary packages installation - restart kubelet
  systemctl restart kubelet.service
  USERDATA


  #Worker node launch config
  instance_type               = "t3a.medium"
  name_prefix                 = "${local.environment}-eksworker"
  # name                        = "${local.environment}-eksworker"
  associate_public_ip_address = true

  # from: https://console.aws.amazon.com/systems-manager/parameters/%252Faws%252Fservice%252Feks%252Foptimized-ami%252F1.19%252Famazon-linux-2%252Frecommended%252Fimage_id/description?region=us-east-2#
  # https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html
  image_id                    = "ami-0b0d79012c6bfa493"
  user_data_base64            = base64encode(local.node-userdata)
  cluster_version             = "1.26"

  #Worker node asg config
  ec2_key_pair     = "bitovi-devops-deploy-eks"
  desired_capacity = 2
  max_size         = 6
  min_size         = 2
  asg_name         = "${local.environment}-eksworker"
  workstation_cidr = ["17.168.95.114/32"]


  common_tags = {
    "terraform"        = "true"
    #RepoName           = "${local.reponame}"
    OpsRepoEnvironment = "${local.environment}"
    OpsRepoApp         = "${local.stackname}"
  }
}

## data lookups
/* 
data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${module.eks_master.cluster_version}-v*"]
  }

  most_recent = true
  owners      = ["755521597925"] # Amazon EKS AMI Account ID
} */
