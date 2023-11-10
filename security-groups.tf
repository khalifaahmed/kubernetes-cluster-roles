
resource "aws_security_group" "grad_proj_sg" {
  for_each    = local.security_groups
  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.my_vpc.id

  dynamic "ingress" { #inbound
    for_each = each.value.ingress
    content {
      description      = ingress.value.description
      from_port        = ingress.value.from
      to_port          = ingress.value.to
      protocol         = ingress.value.protocol
      cidr_blocks      = [var.access_ip_v4]
      ipv6_cidr_blocks = [var.access_ip_v6]
    }

  }
  egress { #outbound
    description      = "allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    # for_each = local.security_groups
    Name = "${var.name}_${each.value.name}"
  }
}

#the loadbalancer security group
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow http/https inbound traffic anywhere"
  vpc_id      = aws_vpc.my_vpc.id

  ingress { #inbound
    description      = "inbound https anywhere"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress { #inbound
    description      = "inbound http anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress { #outbound
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "${var.name}_alb-sg"
  }
}

resource "aws_security_group" "target_group_sg" {
  name        = "target-group-sg"
  description = "Allow http/https inbound traffic anywhere"
  vpc_id      = aws_vpc.my_vpc.id

  ingress { #inbound
    description     = "inbound https from only the alb-sg"
    security_groups = [aws_security_group.alb_sg.id]
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    # cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }
  ingress { #inbound
    description     = "inbound http from only the alb-sg"
    security_groups = [aws_security_group.alb_sg.id]
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
  }
  egress { #outbound
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "${var.name}_target-group-sg"
  }
}


/*
resource "aws_security_group" "http-only" {
  name        = "http-only"
  description = "Allow http/https inbound traffic anywhere"
  vpc_id      = aws_vpc.my_vpc.id

  ingress { #inbound
    description      = "inbound https anywhere"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [var.access_ip_v4]
    ipv6_cidr_blocks = [var.access_ip_v6]
  }
  ingress { #inbound
    description      = "inbound http anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress { #outbound
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "${var.name}_web-only-sg"
  }
}

resource "aws_security_group" "ssh-only" {
  name        = "ssh-only"
  description = "Allow ssh inbound traffic anywhere"
  vpc_id      = aws_vpc.my_vpc.id

  ingress { #inbound
    description      = "inbound ssh anywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.access_ip_v4]
    ipv6_cidr_blocks = [var.access_ip_v6]
  }
  egress { #outbound
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "${var.name}_ssh-only-sg"
  }
}



//data base security group
resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "Allow db port for inbound traffic anywhere"
  vpc_id      = aws_vpc.my_vpc.id

  ingress { #inbound
    description      = "inbound db port anywhere"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = [var.access_ip_v4]
    ipv6_cidr_blocks = [var.access_ip_v6]
  }
  egress { #outbound
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "${var.name}_db-sg"
  }
}

*/
