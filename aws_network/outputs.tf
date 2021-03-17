//-----------------lessin27-----Modules--

output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_subnets_ids" {
  value = aws_subnet.public_subnet[*].id
}

output "private_subnets_ids" {
  value = aws_subnet.private_subnet[*].id
}

output "data_aws_availability_zones" {
  value = data.aws_availability_zones.avalable.names
}
