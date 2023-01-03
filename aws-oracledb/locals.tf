locals {

  devices = formatlist("/dev/sd%s", ["f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p"])

  lvm_pvs = distinct(flatten([
    for vgname, vgmap in var.lvm_vgs : [
      for k in range(0, vgmap.vols_number) :
      {
        pv_size = vgmap.vol_size
        pv_type = vgmap.vol_type
        pv_iops = vgmap.vol_iops
        pv_tput = vgmap.vol_tput
        vg_name = vgname
        pv_name = format("pv-%d", k)
      }
    ]
  ]))

}