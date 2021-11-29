module "shared_vars" {
    source = "../shared_vars"
}

variable "launchtemplatesg"{

}

data "aws_iam_policy" "ecs-ec2role"{
    arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

locals{
    env = "${terraform.workspace}"

    amiid_env={
        default="ami-00c7dbcc1310fd066",
        dev="ami-00c7dbcc1310fd066"
        staging="ami-00c7dbcc1310fd066"
        production="ami-00c7dbcc1310fd066"
    }

    amiid = "${lookup(local.amiid_env, local.env)}"

    instancetype_env = {
        default = "t2.micro"
        dev = "t2.micro"
        staging = "t2.micro"
        production = "t2.small"
    }

    instancetype = "${lookup(local.instancetype_env, local.env)}"

    keypair_env = {
        default = "cfn-key-1"
        dev = "cfn-key-1"
        staging = "cfn-key-1"
        production = "cfn-key-2"
    }

    keypairname = "${lookup(local.keypair_env, local.env)}"

    asgdesired_env = {
        default = "0"
        dev = "0"
        staging = "0"
        production = "0"
    }

    asgdesired = "${lookup(local.asgdesired_env, local.env)}"

    asgmin_env = {
        default = "0"
        dev = "0"
        staging = "0"
        production = "0"
    }

    asgmin = "${lookup(local.asgmin_env, local.env)}"

    asgmax_env = {
        default = "2"
        dev = "2"
        staging = "3"
        production = "10"
    }

    asgmax = "${lookup(local.asgmax_env, local.env)}"



}


resource "aws_iam_role" "launchtemplaterole" {
  name = "launchtemplaterole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "ecsInstanceRole-${module.shared_vars.env_suffix}"
  }
}


resource "aws_iam_role_policy_attachment" "launchtemplate-role-policy-attach" {
  role       = "${aws_iam_role.launchtemplaterole.name}"
  policy_arn = "${data.aws_iam_policy.ecs-ec2role.arn}"
}

resource "aws_iam_instance_profile" "launchtemplate_iam_profile" {   
name  = "launchtemplate_profile"                         
role = "${aws_iam_role.launchtemplaterole.name}"
}


resource "aws_launch_template" "ecs_launch_template" {
  name = "ecs-launch-${module.shared_vars.env_suffix}"
  
  description = "launch template for ${module.shared_vars.env_suffix} environment ECS Cluster"
  image_id = "${local.amiid}"

  instance_type = "${local.instancetype}"
  key_name = "${local.keypairname}"

  vpc_security_group_ids = ["${var.launchtemplatesg}"]

  iam_instance_profile {
    name = "${aws_iam_instance_profile.launchtemplate_iam_profile.name}"
  }


    tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "ecsinstance-${module.shared_vars.env_suffix}"
    }
  }
    tag_specifications {
    resource_type = "volume"

    tags = {
      Name = "ecsinstance-${module.shared_vars.env_suffix}"
    }
  }
  #user_data = "${file("./assets/dev.txt")}"
  user_data = filebase64("./assets/${module.shared_vars.env_suffix}.txt")
  update_default_version = true

}

resource "aws_autoscaling_group" "ecs_asg" {
  name = "bloom-ecs-asg-${module.shared_vars.env_suffix}"
  max_size             = "${local.asgmax}"
  min_size             = "${local.asgmin}"
  desired_capacity     = "${local.asgdesired}"
  vpc_zone_identifier  = ["${module.shared_vars.privatesubnetid}"]
   launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }
  protect_from_scale_in = true

  tags = concat(
    [
      {
        "key"                 = "Name"
        "value"               = "bloom-asg-${module.shared_vars.env_suffix}"
        "propagate_at_launch" = true
      },
      {
        "key"                 = "Environment"
        "value"               = "${module.shared_vars.env_suffix}"
        "propagate_at_launch" = true
      },
    ],
    #var.extra_tags,
  )
}

 output "asg_arn"{
   value = "${aws_autoscaling_group.ecs_asg.arn}"
 }
