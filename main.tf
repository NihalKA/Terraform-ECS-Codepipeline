provider "aws" {
  region = "ap-south-1"
  profile = "personal"
}

terraform {
  backend "s3" {
    bucket = "nihal-terraform-state"
    key    = "ecsdeployment/terraform.tfstate"
    region = "ap-south-1"
    profile = "personal"
  }
}

module "ecs_module" {
    tg_arn = "${module.loadbalancer_module.tg_arn}"
    asg_arn = "${module.autoscaling_module.asg_arn}"
    source = "./ecs_module"
    
}

module "networking_module" {
    source = "./networking_module"
}

module "autoscaling_module"{
    launchtemplatesg = "${module.networking_module.launchtemplatesg}"
    source = "./autoscaling_module"

}

module "loadbalancer_module"{
  alb-sg = "${module.networking_module.alb-sg}"
  source = "./loadbalancer_module"
}

module "codepipeline_module"{
  ecs_cluster_name = "${module.ecs_module.ecs_cluster_name}"
  ecs_service_name = "${module.ecs_module.ecs_service_name}"
  s3projectzip = "sampleAPP.zip"
  pipeline-bucket = "${module.s3buckets_module.pipeline-bucket}"
  code-bucket = "${module.s3buckets_module.code-bucket}"
  container_name = "${module.ecs_module.container_name}"
  source = "./codepipeline_module"
}

module "s3buckets_module"{
  source = "./s3buckets_module"
}


