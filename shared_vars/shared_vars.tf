locals{
    env ="${terraform.workspace}"

    vpcid_env = {
        default = "vpc-2ec92a45"
        dev = "vpc-2ec92a45"
        staging = "vpc-2ec92a45"
        production = "vpc-2ec92a45"
    }
    vpcid = "${lookup(local.vpcid_env, local.env)}"
    

    publicsubnetid1_env ={
        default = "subnet-de5fdfa5"
        dev = "subnet-de5fdfa5"
        staging = "subnet-de5fdfa5"
        production = "subnet-de5fdfa5"

    }
    publicsubnetid1 = "${lookup(local.publicsubnetid1_env, local.env)}"

    publicsubnetid2_env = {
        default = "subnet-1c464e74"
        dev = "subnet-1c464e74"
        staging = "subnet-1c464e74"
        production = "subnet-1c464e74"
    }

    publicsubnetid2 = "${lookup(local.publicsubnetid2_env, local.env)}"

    privatesubnetid_env = {
        default = "subnet-0e12e6dec4a622a2b"
        dev = "subnet-0e12e6dec4a622a2b"
        staging = "subnet-0e12e6dec4a622a2b"
        production = "subnet-0e12e6dec4a622a2b"
    }

    privatesubnetid = "${lookup(local.privatesubnetid_env, local.env)}"

    aws_region_env={
        default = "ap-south-1"
        dev = "ap-south-1"
        staging = "ap-south-1"
        production = "ap-south-1"
    }
    aws_region = "${lookup(local.aws_region_env, local.env)}"

    DockerFilePath_env={
        default = "Dockerfile"
        dev = "Dockerfile"
        staging = "Dockerfile"
        production = "Dockerfile"
    }
    Dockerfile = "${lookup(local.DockerFilePath_env, local.env)}"
    
    AWS_ACCOUNT_ID_env={
        default="710653795817"
        dev="710653795817"
        staging="710653795817"
        production="710653795817"
    }
    AWS_ACCOUNT_ID="${lookup(local.AWS_ACCOUNT_ID_env, local.env)}"

    IMAGE_TAG_env={
        default="latest"
        dev="latest"
        staging="latest"
        production="latest"
    }
    IMAGE_TAG= "${lookup(local.IMAGE_TAG_env, local.env)}"
    IMAGE_REPO_NAME_env={
       default="django-ledger-dev"
       dev="django-ledger-dev"
       staging="django-ledger-dev"
       production="django-ledger-dev"
    }
    IMAGE_REPO_NAME= "${lookup(local.IMAGE_REPO_NAME_env, local.env)}"

    
}


output "env_suffix"{
    value = "${local.env}"
}

output "vpcid" {
    value = "${local.vpcid}"
}

output "privatesubnetid" {
    value = "${local.privatesubnetid}"
}

output "publicsubnetid2"{
    value = "${local.publicsubnetid2}"
}

output "publicsubnetid1"{
    value = "${local.publicsubnetid1}"
}

output "aws_region"{
    value = "${local.aws_region}"
}

output "Dockerfile"{
    value = "${local.Dockerfile}"
}

output "AWS_ACCOUNT_ID"{
    value = "${local.AWS_ACCOUNT_ID}"
}
output "IMAGE_TAG"{
    value = "${local.IMAGE_TAG}"
}

output "IMAGE_REPO_NAME"{
    value = "${local.IMAGE_REPO_NAME}"
}