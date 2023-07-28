
# creating VPC
module "VPC" {
  source         = "../modules/vpc"
  REGION         = var.REGION
  PROJECT_NAME   = var.PROJECT_NAME
  VPC_CIDR       = var.VPC_CIDR
  PUB_SUB_1_CIDR = var.PUB_SUB_1_CIDR
  PUB_SUB_2_CIDR = var.PUB_SUB_2_CIDR
  PRI_SUB_1_CIDR = var.PRI_SUB_1_CIDR
  PRI_SUB_2_CIDR = var.PRI_SUB_2_CIDR
}

# cretea NAT-NAT-GW
module "NAT-GW" {
  source = "../modules/nat-gw"

  PUB_SUB_1_ID = module.VPC.PUB_SUB_1_ID
  IGW_ID       = module.VPC.IGW_ID
  PUB_SUB_2_ID = module.VPC.PUB_SUB_2_ID
  VPC_ID       = module.VPC.VPC_ID
  PRI_SUB_1_ID = module.VPC.PRI_SUB_1_ID
  PRI_SUB_2_ID = module.VPC.PRI_SUB_2_ID
}


module "IAM" {
  source       = "../modules/IAM"
  PROJECT_NAME = var.PROJECT_NAME
}

module "EKS" {
  source               = "../modules/EKS"
  PROJECT_NAME         = var.PROJECT_NAME
  EKS_CLUSTER_ROLE_ARN = module.IAM.EKS_CLUSTER_ROLE_ARN
  PUB_SUB_1_ID         = module.VPC.PUB_SUB_1_ID
  PUB_SUB_2_ID         = module.VPC.PUB_SUB_2_ID
  PRI_SUB_1_ID         = module.VPC.PRI_SUB_1_ID
  PRI_SUB_2_ID         = module.VPC.PRI_SUB_2_ID
}


module "NODE_GROUP" {
  source           = "../modules/Node-group"
  EKS_CLUSTER_NAME = module.EKS.EKS_CLUSTER_NAME
  NODE_GROUP_ARN   = module.IAM.NODE_GROUP_ROLE_ARN
  PRI_SUB_1_ID     = module.VPC.PRI_SUB_1_ID
  PRI_SUB_2_ID     = module.VPC.PRI_SUB_2_ID
}

# --------Create Route 53 DNS zone--------------------
resource "aws_route53_zone" "cloudempowered" {
  name = var.HOSTED_ZONE
}

# Import automatically created Nameserver records to the statefile
resource "aws_route53_record" "nameservers" {
  allow_overwrite = true
  name            = var.HOSTED_ZONE
  ttl             = 3600
  type            = "NS"
  zone_id         = aws_route53_zone.cloudempowered.zone_id
  records         = aws_route53_zone.cloudempowered.name_servers
  depends_on      = [aws_route53_zone.cloudempowered]
}
# create a DNS record to validate the certificate request
/* resource "aws_route53_record" "validation_route53_record" {
  count      = length(aws_acm_certificate.acm_certificate.domain_validation_options)
  name       = element(aws_acm_certificate.acm_certificate.domain_validation_options.*.resource_record_name, count.index)
  type       = element(aws_acm_certificate.acm_certificate.domain_validation_options.*.resource_record_type, count.index)
  zone_id    = aws_route53_zone.cloudempowered.zone_id
  records    = [element(aws_acm_certificate.acm_certificate.domain_validation_options.*.resource_record_value, count.index)]
  ttl        = "60"
  depends_on = [aws_acm_certificate.acm_certificate]
}
 */

resource "aws_route53_record" "validation_route53_record" {
  depends_on = [
    aws_acm_certificate.acm_certificate
  ]
  for_each = {
    for dvo in aws_acm_certificate.acm_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.cloudempowered.zone_id
}
# ----------------------------------------------------
# -------Create SSL certificate for the domain--------
resource "aws_acm_certificate" "acm_certificate" {
  domain_name       = var.HOSTED_ZONE
  subject_alternative_names = ["*.${var.HOSTED_ZONE}"]
  validation_method = "DNS"
  tags = {
    Environment = "prod"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Provides a mechanism to wait for an aws_acm_certificate resource to be validated before it can be used in your Terraform configuration.

resource "aws_acm_certificate_validation" "acm_certificate_validation" {
  certificate_arn         = aws_acm_certificate.acm_certificate.arn
  validation_record_fqdns = aws_acm_certificate.acm_certificate.domain_validation_options[*].resource_record_name
}

# ----------------------------------------------------
