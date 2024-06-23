# Template

<BLOCK TYPE> "<BLOCK LABEL>" "<BLOCK LABEL>" {
# Block body
<IDENTIFIER> = <EXPRESSION> # Argument
}


# AWS EC2 Example

resource "aws_instance" "web_server" { 
# BLOCK
ami  = "ami-04d29b6f966df1537" # Argument
instance_type = var.instance_type # Argument with value as expression (Variable value re
}

---------

provider "aws" {
  access_key = "<YOUR_ACCESSKEY>"
  secret_key = "<YOUR_SECRETKEY>"
  region     = "<REGION>"

}




resource "aws_instance" "web" {
  ami           = "<AMI>"
  instance_type = "t2.micro"
  subnet_id     = "<SUBNET>"
  vpc_security_group_ids = ["<SECURITY_GROUP>"]

  tags = {
    "Identity" = "<IDENTITY>"
  }
}
