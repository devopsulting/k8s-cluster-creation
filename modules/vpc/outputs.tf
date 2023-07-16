output "REGION" {
  value = var.REGION
}

output "PROJECT_NAME" {
  value = var.PROJECT_NAME
}

output "VPC_ID" {
  value = aws_vpc.vpc.id
}

output "PUB_SUB_1_ID" {
  value = aws_subnet.pub-sub-1.id
}
output "PUB_SUB_2_ID" {
  value = aws_subnet.pub-sub-2.id
}
output "PRI_SUB_1_ID" {
  value = aws_subnet.pri-sub-1.id
}

output "PRI_SUB_2_ID" {
  value = aws_subnet.pri-sub-2.id
}
output "IGW_ID" {
    value = aws_internet_gateway.internet_gateway
}