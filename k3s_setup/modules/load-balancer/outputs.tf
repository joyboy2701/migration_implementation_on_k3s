output "alb_arn" {
  value = aws_lb.load_balancer.arn
}

output "alb_dns_name" {
  value = aws_lb.load_balancer.dns_name
}

output "sg_id" {
  value = aws_security_group.alb_sg.id
}

# Output all target groups as a map
output "target_groups" {
  description = "Map of target group names to full target group objects"
  value       = aws_lb_target_group.target_groups
}

# Output target group ARNs as a map
output "target_group_arns" {
  description = "Map of target group names to ARNs"
  value = {
    for name, tg in aws_lb_target_group.target_groups :
    name => tg.arn
  }
}

# Individual TG output (for backward compatibility)
output "target_group" {
  description = "Default target group (first one)"
  value       = length(aws_lb_target_group.target_groups) > 0 ? values(aws_lb_target_group.target_groups)[0] : null
}

output "target_group_arn" {
  description = "Default target group ARN (backward compatibility)"
  value       = length(aws_lb_target_group.target_groups) > 0 ? values(aws_lb_target_group.target_groups)[0].arn : null
}
output "listener_rules" {
  description = "Map of listener rule ARNs"
  value = {
    for key, rule in aws_lb_listener_rule.rules :
    key => rule.arn
  }
}