data "aws_route53_zone" "selected" {
  name         = var.hosted_zone_name   # e.g. "example.com"
  private_zone = var.is_hosted_zone
}
locals {
  tg_attachments = flatten([
    for tg_key, tg in var.target_groups : [
      for t in coalesce(tg.targets, []) : {
        tg_key = tg_key
        ip     = t.ip
        port   = t.port
      }
    ]
  ])
}
resource "aws_security_group" "alb_sg" {
  name        = "${var.name}-alb-sg"
  description = "Security group for ${var.name} ALB"
  vpc_id      = var.vpc_id

  # Single dynamic block for all rules
  dynamic "ingress" {
    for_each = [for rule in var.security_group_rules : rule if rule.type == "ingress"]
    content {
      description     = ingress.value.description
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = ingress.value.cidr_blocks
      security_groups = ingress.value.security_groups
      self            = ingress.value.self
    }
  }

  dynamic "egress" {
    for_each = [for rule in var.security_group_rules : rule if rule.type == "egress"]
    content {
      description     = egress.value.description
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = egress.value.protocol
      cidr_blocks     = egress.value.cidr_blocks
      security_groups = egress.value.security_groups
      self            = egress.value.self
    }
  }

  tags = {
    Name = "${var.name}-alb-sg"
  }
}
resource "aws_lb" "load_balancer" {
  name               = "${var.name}-alb"
  internal           = var.internal
  load_balancer_type = var.load_balancer_type # Use "application" for HTTP/S traffic
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.alb_sg.id]

  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.idle_timeout

  tags = {
    Name = "${var.name}-alb"
  }
}
resource "aws_route53_record" "alb_alias" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.domain_name   
  type    = "A"

  alias {
    name                   = aws_lb.load_balancer.dns_name
    zone_id                = aws_lb.load_balancer.zone_id
    evaluate_target_health = false
  }
}
resource "aws_lb_target_group" "target_groups" {
  for_each = var.target_groups

  name     = each.value.name
  port     = each.value.port
  protocol = each.value.protocol
  vpc_id   = var.vpc_id
  # target_type = var.target_groups.target_type
  target_type = each.value.target_type

  dynamic "health_check" {
    for_each = each.value.health_check != null ? [each.value.health_check] : []

    content {
      path     = try(health_check.value.path, var.target_groups.health_check.path)
      matcher  = try(health_check.value.matcher, var.target_groups.health_check.matcher)
      interval = try(health_check.value.interval, var.target_groups.health_checkhealthcheck_interval)
      # port                = each.value.port
      port                = try(health_check.value.port, null)
      protocol            = each.value.protocol
      healthy_threshold   = try(health_check.value.healthy_threshold, var.target_groups.health_checkhealthcheck_healthy_threshold)
      unhealthy_threshold = try(health_check.value.unhealthy_threshold, var.target_groups.health_check.healthcheck_unhealthy_threshold)
      timeout             = try(health_check.value.timeout, var.target_groups.health_check.healthcheck_healthy_timeout)
    }
  }

  tags = {
    Name = each.value.name
  }
}
resource "aws_lb_target_group_attachment" "attachments" {
  for_each = {
    for idx, val in local.tg_attachments :
    "${val.tg_key}-${idx}" => val
  }

  target_group_arn = aws_lb_target_group.target_groups[each.value.tg_key].arn
  target_id        = each.value.ip
  port             = each.value.port
}

# Create listeners for each protocol/port combination
resource "aws_lb_listener" "listeners" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.load_balancer.arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_groups[each.value.target_group_key].arn
  }
}
resource "aws_lb_listener_rule" "rules" {
  # Correct nested for syntax
  for_each = merge([
    for listener_key, listener in var.listeners : {
      for rule_key, rule in listener.rules :
      "${listener_key}-${rule_key}" => {
        listener_key = listener_key
        rule         = rule
      }
    }
  ]...)

  listener_arn = aws_lb_listener.listeners[each.value.listener_key].arn
  priority     = each.value.rule.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_groups[each.value.rule.target_group_key].arn
  }

  condition {
    dynamic "path_pattern" {
      for_each = each.value.rule.path_patterns
      content {
        values = [path_pattern.value]
      }
    }
  }

  tags = var.tags
}
