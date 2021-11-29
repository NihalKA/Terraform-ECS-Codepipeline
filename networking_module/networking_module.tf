module "shared_vars" {
   source =  "../shared_vars" 
}


resource "aws_security_group" "launch-template-sg" {
  name        = "launchtemplatesg_${module.shared_vars.env_suffix}"
  description = "launch template vpc sg for autoscaling group ${module.shared_vars.env_suffix}"
  vpc_id      = "${module.shared_vars.vpcid}"
  

  ingress = [
    {
      description      = "TLS from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids = null
      security_groups = null
      self = null

      
    },
    {
      description      = "TLS from VPC"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = null
      ipv6_cidr_blocks = null
      prefix_list_ids = null
      security_groups = ["${aws_security_group.alb-sg.id}"]
      self = null

      
    }
  ]

  egress = [
    {
      description      = "outbound of terraform_sg1"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids = null
      security_groups = null
      self = null
      
    }
  ]

  tags = {
    Name = "launchTemplate${module.shared_vars.env_suffix}sg"
  }
}

resource "aws_security_group" "alb-sg" {
  name        = "alb-sg-${module.shared_vars.env_suffix}"
  description = "sg for alb sg ${module.shared_vars.env_suffix}"
  vpc_id      = "${module.shared_vars.vpcid}"
  ingress =[
  
    {
      description      = "TLS from VPC"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids = null
      security_groups = null
      self = null

      
    }
  ]

  egress = [
    {
      description      = "outbound of terraform_sg1"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids = null
      security_groups = null
      self = null
      
    }
  ]

  tags = {
    Name = "alb-sg-${module.shared_vars.env_suffix}sg"
  }
}



output "launchtemplatesg"{
    value = "${aws_security_group.launch-template-sg.id}"
}

output "alb-sg"{
  value = "${aws_security_group.alb-sg.id}"
}