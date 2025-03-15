Creating a full infrastructure for an AWS ECS deployment with CodePipeline, including an Application Load Balancer (ALB) with rules for ports 80 and 443, an ACM certificate, and automatic resource creation when code is pushed to GitHub, is a complex task. Below is a Terraform example that sets up the entire infrastructure.

This example assumes you have a basic understanding of Terraform, AWS, and GitHub. It also assumes you have the AWS CLI configured and Terraform installed.

---

### **Terraform Code**

#### **1. Provider Configuration**
```hcl
provider "aws" {
  region = "us-east-1" # Change to your preferred region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
```

---

#### **2. Variables**
```hcl
variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "your-github-repo"
}

variable "github_branch" {
  description = "GitHub branch to trigger the pipeline"
  type        = string
  default     = "main"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "example.com" # Replace with your domain
}

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "my-app"
}
```

---

#### **3. ACM Certificate**
```hcl
resource "aws_acm_certificate" "app_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Name = "${var.app_name}-certificate"
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

---

#### **4. ECS Cluster**
```hcl
resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.app_name}-cluster"
}
```

---

#### **5. ECS Task Definition**
```hcl
resource "aws_ecs_task_definition" "app_task" {
  family                   = "${var.app_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.app_name}-container"
      image     = "your-docker-image" # Replace with your Docker image
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}
```

---

#### **6. ECS Service**
```hcl
resource "aws_ecs_service" "app_service" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.public.*.id
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "${var.app_name}-container"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.app_listener]
}
```

---

#### **7. Load Balancer**
```hcl
resource "aws_lb" "app_lb" {
  name               = "${var.app_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.public.*.id
}

resource "aws_lb_target_group" "app_tg" {
  name     = "${var.app_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path = "/"
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_listener" "app_listener_https" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.app_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
```

---

#### **8. CodePipeline**
```hcl
resource "aws_codepipeline" "app_pipeline" {
  name     = "${var.app_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.app_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = "your-github-username"
        Repo       = var.github_repo
        Branch     = var.github_branch
        OAuthToken = "your-github-token" # Replace with your GitHub token
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.app_build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ClusterName = aws_ecs_cluster.app_cluster.name
        ServiceName = aws_ecs_service.app_service.name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
```

---

#### **9. IAM Roles**
```hcl
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role" "codepipeline_role" {
  name = "${var.app_name}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}
```

---

#### **10. VPC and Networking**
```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

---

#### **11. Outputs**
```hcl
output "app_url" {
  value = "https://${var.domain_name}"
}
```

---

### **Steps to Deploy**
1. Replace placeholders (e.g., `your-github-repo`, `your-docker-image`, `your-github-token`) with actual values.
2. Run `terraform init` to initialize the Terraform configuration.
3. Run `terraform apply` to create the infrastructure.
4. Push your code to the specified GitHub repository and branch. The pipeline will automatically build and deploy your application.

---

### **End Result**
Once the pipeline completes, you can access your application at `https://<your-domain>`. The infrastructure will automatically handle HTTPS traffic using the ACM certificate.
