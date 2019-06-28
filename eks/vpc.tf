#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

#*
resource "aws_vpc" "aws_eks" {
  cidr_block = "${var.vpc_cidr_prefix}.0.0/16"

  tags = "${
    map(
     "Name", "${var.cluster_name}",
     "kubernetes.io/cluster/${var.cluster_name}", "shared",
    )
  }"
}

#*
resource "aws_subnet" "aws_eks" {
  count = 2

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "${var.vpc_cidr_prefix}.${count.index}.0/24"
  vpc_id            = "${aws_vpc.aws_eks.id}"

  tags = "${
    map(
     "Name", "${var.cluster_name}-node",
     "kubernetes.io/cluster/${var.cluster_name}", "shared",
    )
  }"
}

resource "aws_subnet" "aws_halyard" {
  availability_zone = "${var.ec2_halyard_az}"
  cidr_block        = "${var.vpc_cidr_prefix}.254.0/24"
  vpc_id            = "${aws_vpc.aws_eks.id}"

  tags = {
    Name = "${var.cluster_name}-halyard"
  }
}

#*
resource "aws_internet_gateway" "aws_eks" {
  vpc_id = "${aws_vpc.aws_eks.id}"

  tags = {
    Name = "${var.cluster_name}"
  }
}

#*
resource "aws_route_table" "aws_eks" {
  vpc_id = "${aws_vpc.aws_eks.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.aws_eks.id}"
  }
}

#*
resource "aws_route_table_association" "aws_eks" {
  count = 2

  subnet_id      = "${aws_subnet.aws_eks.*.id[count.index]}"
  route_table_id = "${aws_route_table.aws_eks.id}"
}


#*
resource "aws_route_table_association" "aws_halyard" {
  subnet_id      = "${aws_subnet.aws_halyard.id}"
  route_table_id = "${aws_route_table.aws_eks.id}"
}
