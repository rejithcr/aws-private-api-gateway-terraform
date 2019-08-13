variable "vpc_id" {
}
variable "account_number" {
}
variable "region" {	
}

variable "subnets" {
	type = "list"
}

variable "tags" {
	type = "map"
	default = {
		"Name"            = "private_api"
		"ApplicationName" = "rejith_app"
		"Environment"     = "test"	
		"CreatedBy"		  = "Rejith C R"
    }
}
