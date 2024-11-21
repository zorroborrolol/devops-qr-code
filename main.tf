provider "aws" {
  region = "us-east-1"
}

# Fetch all VPCs
# data "aws_vpcs" "all" {}

# Fetch a specific VPC (e.g., the first one from the list or based on a filter)
#data "aws_vpc" "selected" {
#  id = data.aws_vpcs.all.ids[0] # Use the first VPC
#}

# Fetch details of the existing VPC
data "aws_vpc" "selected" {
  id = "vpc-0a06c8d3ece3e6171" # Your VPC ID
}

# Fetch all subnets in the selected VPC
data "aws_subnet_ids" "all_subnets" {
  vpc_id = data.aws_vpc.selected.id
}

data "aws_subnet" "selected" {
  id = tolist(data.aws_subnet_ids.subnets.ids)[0]
}

# Fetch a specific security group (e.g., by name or ID)
/*data "aws_security_group" "selected" {
  filter {
    name   = "group-name"
    values = ["my-security-group"] # Replace with your specific group name
  }
}*/

data "aws_security_group" "selected" {
  id = "sg-0dc92bfaa49456dc5" # Security group ID
}

resource "aws_instance" "webserver1" {
  ami                    = "ami-0866a3c8686eaeeba"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [data.aws_security_group.selected.id]
  subnet_id              = data.aws_subnet.selected.id
  user_data              = base64encode(file("userdata.sh"))
}

#create alb
resource "aws_lb" "myalb" {
  name               = "nginx-fleet"
  internal           = false
  load_balancer_type = "application"

  security_groups = [data.aws_security_group.selected.id]
  subnets         = [tolist(data.aws_subnet_ids.subnets.ids)[1], tolist(data.aws_subnet_ids.subnets.ids)[2]]

  tags = {
    Name = "web"
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "nginx-server-fleet"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver1.id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}

# Define the Auto Scaling Group (ASG)
resource "aws_autoscaling_group" "web_asg" {
  launch_template {
    id      = aws_launch_template.web_launch_template.id
    version = "$Latest"
  }

  vpc_zone_identifier = data.aws_subnets.all_subnets.ids # Use all subnets in the VPC
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1

  target_group_arns = [aws_lb_target_group.tg.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "asg-instance"
    propagate_at_launch = true
  }
}

# Attach a Target Tracking Scaling Policy
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50 # Target CPU utilization percentage
  }

  # Link the policy to the Auto Scaling Group by specifying the group name here
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}


output "loadbalancerdns" {
  value = aws_lb.myalb.dns_name
}
