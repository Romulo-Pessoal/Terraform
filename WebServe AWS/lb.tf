resource "aws_lb" "Frontend" {
  name               = "frontend-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.external_lb_sg.id]
  subnets            = [aws_subnet.Public_subnet[1].id,aws_subnet.Public_subnet[2].id]

  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}

resource "aws_lb" "Backend" {
  name               = "backend-lb-tf"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_lb_sg.id]
  subnets            = [aws_subnet.Private_subnet_Back[1].id,aws_subnet.Private_subnet_Back[2].id]

  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "frontend" {
  name               = "tffrontendlbtg"
  port               = 80
  protocol           = "HTTP"
  vpc_id             = aws_vpc.VPC.id
}

resource "aws_lb_target_group" "backend" {
  name               = "tfbackendlbtg"
  port               = 8080
  protocol           = "HTTP"
  vpc_id             = aws_vpc.VPC.id
}

resource "aws_lb_target_group_attachment" "frontend" {
  target_group_arn    = aws_lb_target_group.frontend.arn 
  target_id           = aws_instance.Frontend.id
  port                = 80
}
resource "aws_lb_target_group_attachment" "backend" {
  target_group_arn     = aws_lb_target_group.backend.arn 
  target_id            = aws_instance.Backend.id
  port                 = 8080
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn    = aws_lb.Frontend.arn
  port                 = "80"
  protocol             = "HTTP"
  default_action {
    type               = "forward"
    target_group_arn   = aws_lb_target_group.frontend.arn
  }
}
resource "aws_lb_listener" "back_end" {
  load_balancer_arn    = aws_lb.Backend.arn
  port                 = "8080"
  protocol             = "HTTP"
  default_action {
    type               = "forward"
    target_group_arn   = aws_lb_target_group.backend.arn
  }
}

