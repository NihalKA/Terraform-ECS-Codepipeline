module "shared_vars"{
    source = "../shared_vars"
}

variable "asg_arn" {

}

variable "tg_arn"{

}


locals{
  env = "${terraform.workspace}"

  desiredcount_env = {
        default = "2"
        dev = "2"
        staging = "3"
        production = "3"
    }

    desired_count = "${lookup(local.desiredcount_env, local.env)}"

    container_data     = jsondecode(file("./assets/${module.shared_vars.env_suffix}/task_definition.json"))
    containername = "${local.container_data[0].name}"
    log_group_name = "${local.container_data[0].logConfiguration.options.awslogs-group}"

}

# output "containername"{
#   value = "${local.container_data.name}"
# }

#data source for ecs task def role
data "aws_iam_policy" "ecs-taskdef-role-policy"{
    arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#data source for ecs loadbalancer in service role
data "aws_iam_role" "ecs_service_lb_role" {
  name = "AWSServiceRoleForECS"
 //arn = "arn:aws:iam::710653795817:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS"
}

data "aws_iam_policy" "ecs_service_lb_role_policy"{
    arn = "arn:aws:iam::aws:policy/aws-service-role/AmazonECSServiceRolePolicy"
}






resource "aws_ecs_cluster" "sample-cluster" {
  name = "sample-cluster-${module.shared_vars.env_suffix}"
  capacity_providers = ["${aws_ecs_capacity_provider.cp-1.name}"]

  default_capacity_provider_strategy {
    capacity_provider = "${aws_ecs_capacity_provider.cp-1.name}"
    weight = 1
  }
  

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}


resource "aws_ecs_capacity_provider" "cp-1" {
  name = "bloom-ECS-CP-${module.shared_vars.env_suffix}"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = "${var.asg_arn}"
    managed_termination_protection = "ENABLED"

    managed_scaling {
  #    maximum_scaling_step_size = 1000
  #    minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}


#create IAM role for task defenition
resource "aws_iam_role" "ecs-taskdef-role" {
  name = "ecs-taskdef-role-${module.shared_vars.env_suffix}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "ecstaskdefRole-${module.shared_vars.env_suffix}"
  }
}

#attach policy to above created ecs taskdef role
resource "aws_iam_role_policy_attachment" "ecs-taskdef-role-policy-attach" {
  role       = "${aws_iam_role.ecs-taskdef-role.name}"
  policy_arn = "${data.aws_iam_policy.ecs-taskdef-role-policy.arn}"
}


# create IAM role policy for ECS loadbalancer

# resource "aws_iam_role_policy" "ecs_service_role_policy" {
#   name     = "ecs_service_role_policy"
#   policy   = "${data.aws_iam_policy.ecs_service_lb_role_policy.policy}"
#   role     = "${data.aws_iam_role.ecs_service_lb_role.id}"
# }


# create task definiton for ECS-Ec2

resource "aws_ecs_task_definition" "task_definition_bloom" {
  container_definitions    = "${data.template_file.task_definition_json.rendered}"                                         # task defination json file location
  execution_role_arn       = "${aws_iam_role.ecs-taskdef-role.arn}" #CHANGE THIS                                                                      # role for executing task
  family                   = "bloom-${module.shared_vars.env_suffix}-task-defination"                                                                      # task name
  network_mode             = "bridge"                                                                                      # network mode awsvpc, brigde
 # memory                   = "2048"
 # cpu                      = "1024"
  requires_compatibilities = ["EC2"]                                                                                       # Fargate or EC2
  task_role_arn            = "${aws_iam_role.ecs-taskdef-role.arn}"  #CHANGE THIS                                                                     # TASK running role
} 

data "template_file" "task_definition_json" {
#  template = "${file("${path.module}/task_definition.json")}"
  template = file("./assets/${module.shared_vars.env_suffix}/task_definition.json")
}

// create ecs django service

resource "aws_ecs_service" "django-service" {
  name            = "django-service-${module.shared_vars.env_suffix}"
  cluster         = aws_ecs_cluster.sample-cluster.id
  task_definition = aws_ecs_task_definition.task_definition_bloom.arn
  desired_count   = "${local.desired_count}"
  iam_role        = data.aws_iam_role.ecs_service_lb_role.arn
  //depends_on      = [aws_iam_role_policy.ecs_service_role_policy]

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    target_group_arn = "${var.tg_arn}"
    container_name   = "${local.containername}"
    container_port   = 8000
  }

  # placement_constraints {
  #   type       = "memberOf"
  #   expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  # }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "${local.log_group_name}"
    tags = {
    Environment = "production"
  }
}

output "ecs_cluster_name"{
  value = "${aws_ecs_cluster.sample-cluster.name}"
}

output "ecs_service_name"{
  value = "${aws_ecs_service.django-service.name}"
}

output "container_name"{
  value = "${local.container_data[0].name}"
}