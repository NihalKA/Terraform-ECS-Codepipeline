variable "alb-sg"{

}



module "shared_vars" {
   source =  "../shared_vars" 
}

// create load balancer 
resource "aws_lb" "sampleapp_alb" {
  name               = "sampleapp-alb-${module.shared_vars.env_suffix}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${var.alb-sg}"]
  subnets            = ["${module.shared_vars.publicsubnetid1}","${module.shared_vars.publicsubnetid2}"]

  enable_deletion_protection = true

  

  tags = {
    Environment = "${module.shared_vars.env_suffix}"
  }
}


//create a listner rule for loadbalancers
resource "aws_lb_listener" "http_listener_80" {
  load_balancer_arn = aws_lb.sampleapp_alb.arn
  port              = "80"
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
 #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sampleapp_http_tg.arn
  }
}

//create target group

resource "aws_lb_target_group" "sampleapp_http_tg" {
  name     = "sampleapp-http-tg-${module.shared_vars.env_suffix}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${module.shared_vars.vpcid}"
  health_check {
    path                = "/admin"
    protocol            = "HTTP"
    healthy_threshold   = 5
    unhealthy_threshold = 3
    matcher             = "200-499"
  } 
}

output "tg_arn" {
  value = "${aws_lb_target_group.sampleapp_http_tg.arn}"
}