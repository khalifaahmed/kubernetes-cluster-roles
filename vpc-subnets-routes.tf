resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  #Enable dns 
  enable_dns_hostnames = true
  enable_dns_support   = true
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "${var.name}_vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.name}_igw"
  }
}

data "aws_region" "current_region" {}

output "the_current_region_man" {
  value = data.aws_region.current_region.name
}

data "aws_availability_zones" "available" {}

output "number_of_az_in_this_region" {
  value = length(data.aws_availability_zones.available.names)
}


resource "random_shuffle" "az_list" {
  input        = data.aws_availability_zones.available.names
  result_count = local.max_subnets
}

resource "aws_subnet" "public" {
  count                   = local.public_subnet_count
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = local.public_cidrs[count.index]            #cidr_block = [for i in range(1, 255, 2) : cidrsubnet("10.0.0.0/16", 8, i)][count.index]
  availability_zone       = random_shuffle.az_list.result[count.index] #availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}_public_${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count                   = local.private_subnet_count
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = local.private_cidrs[count.index]           #cidr_block = [for i in range(2, 255, 2) : cidrsubnet("10.0.0.0/16", 8, i)][count.index]
  availability_zone       = random_shuffle.az_list.result[count.index] #availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.name}_private_${count.index + 1}"
  }
}



resource "aws_route_table" "public" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.name}_public_RT"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.name}_private_RT"
  }
}

resource "aws_default_route_table" "my_vpc_default_route_table" {
  default_route_table_id = aws_vpc.my_vpc.default_route_table_id

  tags = {
    Name = "${var.name}_default_RT"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public" {
  count          = local.public_subnet_count
  subnet_id      = aws_subnet.public.*.id[count.index]
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = local.private_subnet_count
  subnet_id      = aws_subnet.private.*.id[count.index]
  route_table_id = aws_route_table.private.id
}

# resource "aws_route_table_association" "public2" {
#   subnet_id      = aws_subnet.public2.id
#   route_table_id = aws_route_table.public.id
# }
# resource "aws_route_table_association" "public3" {
#   subnet_id      = aws_subnet.public3.id
#   route_table_id = aws_route_table.public.id
# }
# resource "aws_route_table_association" "private2" {
#   subnet_id      = aws_subnet.private2.id
#   route_table_id = aws_route_table.private.id
# }
# resource "aws_route_table_association" "private3" {
#   subnet_id      = aws_subnet.private3.id
#   route_table_id = aws_route_table.private.id
# }

