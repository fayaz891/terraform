# Terraform Variables: Complete Tutorial with Examples

## Introduction to Terraform Variables

Variables in Terraform allow you to make your configurations more flexible and reusable by parameterizing your infrastructure definitions. This tutorial will walk you through the various types of Terraform variables, how to declare and use them, and best practices with real-world examples.

## Table of Contents

1. [Basic Variable Declaration](#basic-variable-declaration)
2. [Variable Types](#variable-types)
3. [Input Variables](#input-variables)
4. [Local Variables](#local-variables)
5. [Output Variables](#output-variables)
6. [Variable Files](#variable-files)
7. [Environment Variables](#environment-variables)
8. [Variable Precedence](#variable-precedence)
9. [Sensitive Variables](#sensitive-variables)
10. [Conditional Variable Assignment](#conditional-variable-assignment)
11. [Real-World Examples](#real-world-examples)
12. [Best Practices](#best-practices)

## Basic Variable Declaration

Variables in Terraform are declared using the `variable` block:

```hcl
variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}
```

This example defines a variable named `region` with:
- A description that explains its purpose
- A type constraint ensuring it's a string
- A default value of "us-west-2"

To reference this variable in your Terraform configuration:

```hcl
provider "aws" {
  region = var.region
}
```

## Variable Types

Terraform supports several variable types:

### Simple Types

```hcl
variable "instance_name" {
  type    = string
  default = "web-server"
}

variable "instance_count" {
  type    = number
  default = 2
}

variable "enable_monitoring" {
  type    = bool
  default = true
}
```

### Complex Types

#### Lists/Tuples

```hcl
variable "availability_zones" {
  type    = list(string)
  default = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

# Using a tuple (fixed-length list with potentially different types)
variable "instance_settings" {
  type    = tuple([string, number, bool])
  default = ["t2.micro", 1, true]  # instance type, count, monitoring
}
```

#### Maps/Objects

```hcl
variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Project     = "example"
  }
}

# Using an object (with named attributes of potentially different types)
variable "instance_config" {
  type = object({
    instance_type = string
    count         = number
    monitoring    = bool
    tags          = map(string)
  })
  
  default = {
    instance_type = "t2.micro"
    count         = 1
    monitoring    = true
    tags = {
      Name = "web-server"
    }
  }
}
```

#### Sets

```hcl
variable "allowed_ports" {
  type    = set(number)
  default = [22, 80, 443]
}
```

## Input Variables

Input variables allow you to customize your infrastructure without changing the Terraform code.

### Command Line Input

When running Terraform commands, you can specify variable values directly:

```bash
terraform apply -var="region=us-east-1" -var="instance_count=3"
```

## Local Variables

Local variables are useful for simplifying expressions and reusing values within a module:

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
  
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_instance" "example" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-instance"
    }
  )
}
```

## Output Variables

Output variables make information about your infrastructure available to other Terraform configurations or to the user after applying:

```hcl
output "instance_ip_addr" {
  value       = aws_instance.example.public_ip
  description = "The public IP address of the instance"
}

output "load_balancer_dns" {
  value       = aws_lb.example.dns_name
  description = "The DNS name of the load balancer"
  sensitive   = false
}
```

## Variable Files

You can store variable values in separate files to organize your configurations.

### terraform.tfvars

This is the default file that Terraform will load automatically:

```hcl
# terraform.tfvars
region         = "us-east-1"
instance_type  = "t2.micro"
instance_count = 2
```

### Custom Variable Files

You can also create custom .tfvars files:

```hcl
# production.tfvars
region         = "us-west-2"
instance_type  = "t2.medium"
instance_count = 5
```

To use a custom variable file:

```bash
terraform apply -var-file="production.tfvars"
```

### Automatically Loaded Variable Files

Terraform automatically loads:
- Files named exactly `terraform.tfvars` or `terraform.tfvars.json`
- Any files with names ending in `.auto.tfvars` or `.auto.tfvars.json`

```hcl
# dev.auto.tfvars
environment = "development"
```

## Environment Variables

You can set Terraform variables using environment variables with the `TF_VAR_` prefix:

```bash
export TF_VAR_region="us-west-2"
export TF_VAR_instance_count=3
terraform apply
```

## Variable Precedence

Terraform uses the following order of precedence for variable values (from highest to lowest):

1. Command-line flags (-var or -var-file)
2. *.auto.tfvars files (alphabetical order)
3. terraform.tfvars
4. Environment variables (TF_VAR_*)
5. Default values

## Sensitive Variables

For sensitive data like passwords or API keys, you can mark variables as sensitive:

```hcl
variable "database_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
}
```

Terraform will hide the values of sensitive variables in output and logs.

## Conditional Variable Assignment

You can use conditionals to set variable values based on other values:

```hcl
locals {
  instance_type = var.environment == "production" ? "t2.medium" : "t2.micro"
}
```

## Real-World Examples

### AWS Infrastructure with Variables

```hcl
# variables.tf
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "CIDR blocks for the subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "instance_config" {
  description = "Configuration for EC2 instances"
  type = object({
    ami           = string
    instance_type = string
    count         = number
  })
}

# main.tf
provider "aws" {
  region = var.region
}

locals {
  name_prefix = "${var.environment}-app"
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "Infrastructure Example"
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-vpc"
    }
  )
}

resource "aws_subnet" "main" {
  count      = length(var.subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidrs[count.index]
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-subnet-${count.index + 1}"
    }
  )
}

resource "aws_instance" "app" {
  count         = var.instance_config.count
  ami           = var.instance_config.ami
  instance_type = var.instance_config.instance_type
  subnet_id     = aws_subnet.main[count.index % length(aws_subnet.main)].id
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-instance-${count.index + 1}"
    }
  )
}

# outputs.tf
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "IDs of the created subnets"
  value       = aws_subnet.main[*].id
}

output "instance_ids" {
  description = "IDs of the created EC2 instances"
  value       = aws_instance.app[*].id
}

# production.tfvars
environment = "production"
region      = "us-east-1"
vpc_cidr    = "10.1.0.0/16"
subnet_cidrs = [
  "10.1.1.0/24",
  "10.1.2.0/24",
  "10.1.3.0/24",
  "10.1.4.0/24"
]
instance_config = {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.medium"
  count         = 4
}
```

### Multi-Environment Deployment

```hcl
# variables.tf
variable "environments" {
  description = "Configuration for multiple environments"
  type = map(object({
    vpc_cidr     = string
    subnet_cidrs = list(string)
    instance_type = string
    asg_min_size = number
    asg_max_size = number
  }))
  
  default = {
    dev = {
      vpc_cidr     = "10.0.0.0/16"
      subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
      instance_type = "t2.micro"
      asg_min_size = 1
      asg_max_size = 3
    }
    staging = {
      vpc_cidr     = "10.1.0.0/16"
      subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
      instance_type = "t2.small"
      asg_min_size = 2
      asg_max_size = 4
    }
    production = {
      vpc_cidr     = "10.2.0.0/16"
      subnet_cidrs = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24", "10.2.4.0/24"]
      instance_type = "t2.medium"
      asg_min_size = 3
      asg_max_size = 10
    }
  }
}

variable "environment" {
  description = "Environment to deploy"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Valid values for environment are: dev, staging, production."
  }
}

# main.tf
locals {
  # Get the configuration for the current environment
  env_config = var.environments[var.environment]
}

resource "aws_vpc" "main" {
  cidr_block = local.env_config.vpc_cidr
  
  tags = {
    Name = "${var.environment}-vpc"
  }
}

resource "aws_subnet" "main" {
  count      = length(local.env_config.subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = local.env_config.subnet_cidrs[count.index]
  
  tags = {
    Name = "${var.environment}-subnet-${count.index + 1}"
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-app-"
  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = local.env_config.instance_type
  
  # Other launch template configurations...
}

resource "aws_autoscaling_group" "app" {
  min_size         = local.env_config.asg_min_size
  max_size         = local.env_config.asg_max_size
  desired_capacity = local.env_config.asg_min_size
  vpc_zone_identifier = aws_subnet.main[*].id
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  # Other autoscaling group configurations...
}
```

## Best Practices

1. **Always Include Descriptions**: Add a description to every variable to document its purpose.

2. **Set Type Constraints**: Always specify the variable type to catch errors early.

3. **Use Validation**: Add validation rules to ensure variables meet your requirements.

   ```hcl
   variable "environment" {
     type        = string
     description = "Environment to deploy to"
     
     validation {
       condition     = contains(["dev", "staging", "production"], var.environment)
       error_message = "Environment must be one of: dev, staging, production."
     }
   }
   ```

4. **Use Default Values Wisely**: Provide sensible defaults when appropriate, but require input for critical values.

5. **Organize Your Variables**: Group related variables in your `variables.tf` file.

6. **Mark Sensitive Data**: Always use the `sensitive = true` attribute for credentials and other sensitive data.

7. **Use Environment-Specific Variable Files**: Create separate `.tfvars` files for different environments.

8. **Use Local Variables for Computed Values**: Use `locals` for values that are derived from other variables.

9. **Limit Variable Scope**: Use input variables at the module level, and local variables for internal module calculations.

10. **Thoroughly Document Output Variables**: Make sure outputs are well-described for users of your module.

## Conclusion

Terraform variables are a powerful tool for creating flexible, reusable, and maintainable infrastructure code. By following the patterns and best practices in this tutorial, you can create Terraform configurations that are easy to understand, scale, and adapt to changing requirements.

Remember that proper variable management is key to successful Infrastructure as Code practices, especially in team environments and across multiple deployment environments.


# Terraform Variables Tutorial

I've created a comprehensive guide to Terraform variables with practical examples that you can start using right away. Here's what the tutorial covers:

## Basic Variable Usage
Variables in Terraform allow you to write more flexible and reusable infrastructure code. The tutorial explains how to:

- Declare basic variables with types (string, number, bool)
- Set default values for variables
- Add descriptions and validations
- Reference variables in your configuration

## Variable Types in Detail
The guide covers all Terraform variable types including:

- Simple types: strings, numbers, booleans
- Complex types: lists, maps, sets
- Structured types: objects and tuples
- When to use each type with real examples

## Where to Define Variable Values
You'll learn multiple ways to set variable values:

- Default values in variable declarations
- Command line flags (-var and -var-file)
- Environment variables (TF_VAR_*)
- Variable files (.tfvars)
- Auto-loaded variable files

## Advanced Variable Techniques
The guide also includes more advanced topics:

- Local variables for computed values
- Output variables to share information
- Sensitive variables for secrets
- Conditional variable assignments
- Variable validation rules

## Real-World Examples
The tutorial includes complete examples for:

- AWS infrastructure deployment with environment-specific configuration
- Multi-environment setup using maps of objects
- Properly structured Terraform projects

Would you like me to explain any specific part of using Terraform variables in more detail? Or do you have a specific scenario you'd like help implementing?
