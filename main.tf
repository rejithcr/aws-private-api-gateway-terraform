provider "aws" {
	region = "${var.region}"
}

resource "aws_security_group" "private_api_sg" {
  name        = "private_api_sg"
  description = "private api gateway"
  vpc_id      = "${var.vpc_id}"	

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["10.0.0.0/8"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/8"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = "${var.tags}"
}

/* VPC endpoint for execute api */
resource "aws_vpc_endpoint" "private_api_vpce" {
  vpc_id            = "${var.vpc_id}"	
  service_name      = "com.amazonaws.us-east-1.execute-api"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  security_group_ids = [aws_security_group.private_api_sg.id]
  #specify private subnets. Otheriwise it will take default subnets
  subnet_ids          = "${var.subnets}"
  tags = "${var.tags}"
}

/* API gateway */
resource "aws_api_gateway_rest_api" "private_api" {
  name        = "private_api"
  description = "This is my API for demonstration purposes"
  endpoint_configuration {
    types = ["PRIVATE"]
  }
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": "execute-api:Invoke",
            "Resource": "arn:aws:execute-api:${var.region}:${var.account_number}:*/*/*/*",
            "Condition": {
                "StringNotEquals": {
                    "aws:sourceVpc": "${var.vpc_id}"
                }
            }
        },
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "execute-api:Invoke",
            "Resource": "arn:aws:execute-api:${var.region}:${var.account_number}:*/*/*/*"
        }
    ]
}
EOF
}

resource "aws_api_gateway_resource" "private_api_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.private_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.private_api.root_resource_id}"
  path_part   = "privateapi"
}

resource "aws_api_gateway_method" "private_api_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.private_api.id}"
  resource_id   = "${aws_api_gateway_resource.private_api_resource.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "private_api_integration" {
  rest_api_id = "${aws_api_gateway_rest_api.private_api.id}"
  resource_id = "${aws_api_gateway_resource.private_api_resource.id}"
  http_method = "${aws_api_gateway_method.private_api_method.http_method}"
  type        = "MOCK"
  request_templates = {
    "application/json" = <<EOF
{"statusCode": 200}
EOF
  }
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = "${aws_api_gateway_rest_api.private_api.id}"
  resource_id = "${aws_api_gateway_resource.private_api_resource.id}"
  http_method = "${aws_api_gateway_method.private_api_method.http_method}"
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "private_api_integration_response" {
  rest_api_id = "${aws_api_gateway_rest_api.private_api.id}"
  resource_id = "${aws_api_gateway_resource.private_api_resource.id}"
  http_method = "${aws_api_gateway_method.private_api_method.http_method}"
  status_code = "${aws_api_gateway_method_response.response_200.status_code}"
  response_templates = {
    "application/json" = <<EOF
{"statusCode": 200, "message":"Hello world, I am private!!"}
EOF
  }
}

resource "aws_api_gateway_deployment" "private_api_deployment" {
  depends_on = ["aws_api_gateway_integration.private_api_integration"]
  rest_api_id = "${aws_api_gateway_rest_api.private_api.id}"
  stage_name  = "test"
}

/* Creating an EC2 if you want to test the api. If you have EC2 already in same vpc, then skip this */
resource "aws_instance" "private_api_ec2" {
  instance_type        = "t2.micro"
  ami		       = "ami-0b898040803850657"
  #specify one of the subnet in the vpc endpoint 
  subnet_id            = "${var.subnets[0]}"
  key_name             = "aws-124163686835-non-prod-crre01"
  security_groups      = [aws_security_group.private_api_sg.id]
  tags = "${var.tags}"
}
