output "instance_id" {
  value = module.oracledb_server.id
}

output "private_ip" {
  value = module.oracledb_server.private_ip
}

output "lvm_pvs" {
  value = { for j, pv in local.lvm_pvs : format("%s-%s", local.lvm_pvs[j].vg_name, local.lvm_pvs[j].pv_name) => pv }
}

output "lvm_lvs" {
  value = var.lvm_lvs
}