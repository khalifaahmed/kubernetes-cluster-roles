resource "aws_lb" "nginx_controller_alb" {
  name                       = "nginx-controller-alb"
  internal                   = false
  load_balancer_type         = "application"
  enable_deletion_protection = false

  # attach to the loadbalancer a unique security group just for it, but the public one just for testing purposes
  security_groups = ["${aws_security_group.alb_sg.id}", "${aws_security_group.grad_proj_sg["public"].id}"]

  # make the loadbalancer avalaible in each avalaibility zone ih the specified region
  subnets = [for i in range(0, length(data.aws_availability_zones.available.names), 1) : aws_subnet.public[i].id]

}

resource "aws_lb_target_group" "nginx_controller_tg" {
  name     = "nginx-controller-tg"
  port     = 30100
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
}

resource "aws_lb_listener" "nginx_controller_listener" {
  load_balancer_arn = aws_lb.nginx_controller_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_controller_tg.arn
  }
}

#resource "aws_lb_target_group_attachment" "nginx_controller_tg_attach_0" {
#  target_group_arn = aws_lb_target_group.nginx_controller_tg.arn
#  target_id        = aws_instance.worker_nodes[0].id
#  port             = 30100
#
#  depends_on = [ aws_instance.worker_nodes[0] ]
#}
#
#resource "aws_lb_target_group_attachment" "nginx_controller_tg_attach_1" {
#  target_group_arn = aws_lb_target_group.nginx_controller_tg.arn
#  target_id        = aws_instance.worker_nodes[1].id
#  port             = 30100
#
#  depends_on = [ aws_instance.worker_nodes[1] ]
#}


resource "aws_alb_target_group_attachment" "tg_attachment" {
  count            = local.worker_nodes_count
  target_group_arn = aws_lb_target_group.nginx_controller_tg.arn
  target_id        = element(split(",", join(",", aws_instance.worker_nodes.*.id)), count.index)
}

data "aws_instances" "worker_instances" {

  instance_state_names = ["running"]

  instance_tags = {
    "worker" = "true"
  }
  depends_on = [aws_instance.master_nodes[0], aws_instance.worker_nodes[0], aws_instance.worker_nodes[1]]
}

output "worker_nodes_ids" {
  value = data.aws_instances.worker_instances.ids
}

#resource "aws_lb_target_group_attachment" "worker_lb_instances" {
#  for_each         = toset(data.aws_instances.worker_instances.ids)
#  target_group_arn = aws_lb_target_group.nginx_controller_tg.arn
#  target_id        = each.value
#  depends_on = [data.aws_instances.worker_instances]
#}
