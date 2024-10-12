locals {
  len_public_subnets      = max(length(var.public_subnets))#, length(var.public_subnet_ipv6_prefixes))
  len_private_subnets     = max(length(var.private_subnets))#, length(var.private_subnet_ipv6_prefixes))
 # len_database_subnets    = max(length(var.database_subnets), length(var.database_subnet_ipv6_prefixes))
 # len_elasticache_subnets = max(length(var.elasticache_subnets), length(var.elasticache_subnet_ipv6_prefixes))
 # len_redshift_subnets    = max(length(var.redshift_subnets), length(var.redshift_subnet_ipv6_prefixes))
 # len_intra_subnets       = max(length(var.intra_subnets), length(var.intra_subnet_ipv6_prefixes))
 # len_outpost_subnets     = max(length(var.outpost_subnets), length(var.outpost_subnet_ipv6_prefixes))

  max_subnet_length = max(
    local.len_private_subnets,
    local.len_public_subnets,
   # local.len_elasticache_subnets,
   # local.len_database_subnets,
   # local.len_redshift_subnets,
  )

  # Use `local.vpc_id` to give a hint to Terraform that subnets should be deleted before secondary CIDR blocks can be free!
  vpc_id = try(aws_vpc_ipv4_cidr_block_association.this[0].vpc_id, aws_vpc.this[0].id, "")

  create_vpc = var.create_vpc && var.putin_khuylo
}


resource "aws_vpc" "this" {
  count = local.create_vpc ? 1 : 0

  cidr_block          = var.use_ipam_pool ? null : var.cidr
  ipv4_ipam_pool_id   = var.ipv4_ipam_pool_id
  ipv4_netmask_length = var.ipv4_netmask_length
  instance_tenancy = var.instance_tenancy
  enable_dns_hostnames     = var.enable_dns_hostnames
  enable_dns_support       = var.enable_dns_support
  
  tags = merge(
    { "Name" = var.name },
    var.tags,
    var.vpc_tags,
  )
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  count = local.create_vpc && length(var.secondary_cidr_blocks) > 0 ? length(var.secondary_cidr_blocks) : 0

  # Do not turn this into `local.vpc_id`
  vpc_id = aws_vpc.this[0].id

  cidr_block = element(var.secondary_cidr_blocks, count.index)
}


resource "aws_subnet" "public" {
  availability_zone = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  cidr_block = var.public_subnet_ipv6_native ? null : element(concat(var.public_subnets, [""]), count.index)
  enable_dns64                                   = var.enable_ipv6 && var.public_subnet_enable_dns64
  map_public_ip_on_launch                        = var.map_public_ip_on_launch
  vpc_id = aws_vpc.this.id


}

resource "aws_subnet" "private" {
  availability_zone                              = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id                           = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  cidr_block                                     = var.private_subnet_ipv6_native ? null : element(concat(var.private_subnets, [""]), count.index)
  vpc_id = aws_vpc.this.id
}