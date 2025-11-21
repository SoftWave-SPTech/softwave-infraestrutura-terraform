output "vpc_id" {
value = aws_vpc.main.id
}


output "public_subnets" {
value = aws_subnet.public[*].id
}


output "private_subnets" {
value = aws_subnet.private[*].id
}


output "frontend_instances" {
value = aws_instance.frontend[*].id
}


output "backend_instances" {
value = aws_instance.backend[*].id
}


output "nat_eip" {
value = aws_eip.nat_eip.public_ip
}


output "nat_gateway_id" {
value = aws_nat_gateway.natgw.id
}