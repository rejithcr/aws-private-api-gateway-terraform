# aws-private-api-gateway-terraform
Infrastructure as code to construct the private endpoint in aws api gateway using terraform.
This is the terraform code to construct a private api gateway which consists of below resources
1. VPC Endpoint
2. Security Group
3. API Gateway 
    * Rest API with mocked response
    * Deployment to test stage
    * Includes resource policy to allow access only from specific VPC
    
##Prerequisite
1. Terraform v0.12.3 (terraform should be added to the PATH variable in env)
2. AWS access to create the above resources

##How to run
1. Checkout the code
2. cd to the checked out directory
3. run the command
    * terraform apply
4. enter the parameters as prompted
    * vpc_id
    * account_number
    * region
    * subnet ids. eg. ["subnet-1","subnet-2"]
