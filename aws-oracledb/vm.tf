module "oracledb_server" { #tfsec:ignore:AWS079
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.1.4"

  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  iam_instance_profile = aws_iam_instance_profile.instance_profile.id

  user_data_base64 = base64encode(templatefile(
    "${path.module}/templates/user_data.tpl",
    {
      fqdn       = var.fqdn
      ssh_keys   = join(",", [for k, v in var.ssh_pubkeys : v])
      login_name = var.login_name
      json_pvs   = jsonencode({ for j, pv in local.lvm_pvs : format("%s-%s", local.lvm_pvs[j].vg_name, local.lvm_pvs[j].pv_name) => pv })
      json_lvs   = jsonencode(var.lvm_lvs)
      lvm_setup  = filebase64("${path.module}/templates/configure-lvm.sh")
    }
  ))

  ami = var.ami_id

  root_block_device = [
    {
      encrypted   = true
      volume_type = var.root_volume_type
      volume_size = var.root_volume_size
      throughput  = var.root_volume_tput
      tags = {
        Name = format("rootvol-oracledb-%s", var.resource_name_prefix)
      }
    }
  ]

  enable_volume_tags = false

  vpc_security_group_ids = var.user_supplied_sg_ids != null ? var.user_supplied_sg_ids : [aws_security_group.oracledb.id]

  tags = {
    Terraform   = "true"
    Environment = var.resource_name_prefix
    Name        = format("%s-oracledb-server", var.resource_name_prefix)
  }
}


resource "aws_volume_attachment" "lvm_volume_attachment" {

  count = length(local.lvm_pvs)

  device_name = local.devices[count.index]
  volume_id   = aws_ebs_volume.lvm_volume[count.index].id
  instance_id = module.oracledb_server.id
}

resource "aws_ebs_volume" "lvm_volume" {

  count = length(local.lvm_pvs)

  encrypted         = true
  availability_zone = var.az
  size              = local.lvm_pvs[count.index].pv_size
  type              = local.lvm_pvs[count.index].pv_type
  iops              = local.lvm_pvs[count.index].pv_iops
  throughput        = local.lvm_pvs[count.index].pv_tput
  tags = {
    Name = format("oracledb-vol%d", count.index)
    PV   = format("%s", local.lvm_pvs[count.index].pv_name)
    VG   = format("%s", local.lvm_pvs[count.index].vg_name)
  }
}
