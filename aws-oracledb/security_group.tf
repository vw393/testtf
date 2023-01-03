resource "aws_security_group" "oracledb" {
  name        = "${var.resource_name_prefix}-oracledb-server"
  description = "Security Group of the ${var.resource_name_prefix} Oracle DB server"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.resource_name_prefix}-oracledb-server-sg"
  }
}

resource "aws_security_group_rule" "oracledb_inbound_sgs" {

  for_each = { for rule in var.inbound_access_rules : format("%s_%d", rule.name, rule.port) => rule }

  description              = each.value.descr
  security_group_id        = aws_security_group.oracledb.id
  type                     = "ingress"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = each.value.protocol
  source_security_group_id = each.value.sgid
}


resource "aws_security_group_rule" "oracledb_outbound_any" {
  description       = "Allow Oracle DB server to send outbound traffic"
  security_group_id = aws_security_group.oracledb.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] #tfsec:ignore:AWS007
}
